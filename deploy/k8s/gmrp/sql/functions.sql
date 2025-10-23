-- By turning this off here and back on at the bottom, we can load this file before running our migrations, allowing
-- the migrations to safely refer to these functions and these functions to safely refer to any tables from the migrations.
set check_function_bodies = off;

CREATE OR REPLACE FUNCTION user_groups(p_user_id text) RETURNS text[] AS
$$
    SELECT array_agg(name) FROM group_members m JOIN groups g ON g.id = m.group_id WHERE
        user_id = p_user_id GROUP BY user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION group_members(p_group_name text) RETURNS text[] AS
$$
    SELECT array_agg(user_id) FROM group_members m JOIN groups g ON g.id = m.group_id WHERE
        name = p_group_name GROUP BY group_id;
$$ LANGUAGE sql;

-- Helper function for users_with_access
CREATE OR REPLACE FUNCTION user_users_with_access_level(p_namespace text, p_type text, p_id text, p_level access_level) RETURNS text[] AS
$$
    SELECT users FROM object_acl WHERE namespace = p_namespace AND type = p_type AND id = p_id AND access_level = p_level;
$$ LANGUAGE sql;

-- Helper function for users_with_access
CREATE OR REPLACE FUNCTION group_users_with_access_level(p_namespace text, p_type text, p_id text, p_level access_level) RETURNS text[] AS
$$
    SELECT array_agg(unnest) FROM (SELECT unnest(group_members(unnest(groups))) FROM object_acl WHERE
        namespace = p_namespace AND type = p_type AND id = p_id AND access_level = p_level) _;
$$ LANGUAGE sql;

-- Based on https://stackoverflow.com/a/64651280
CREATE OR REPLACE FUNCTION array_remove_many(anyarray, anyarray) RETURNS anyarray
    LANGUAGE sql immutable
AS $$
    SELECT array_agg(x) FROM unnest($1) AS x WHERE x <> all($2)
$$;

CREATE OR REPLACE FUNCTION array_set_union(anyarray, anyarray) RETURNS anyarray
    LANGUAGE sql immutable
AS $$
    SELECT ARRAY(SELECT DISTINCT UNNEST($1 || $2))
$$;

CREATE OR REPLACE FUNCTION cleared_users(p_users text[], p_level text, p_caveates text[], p_reltos text[]) RETURNS text[]
    LANGUAGE sql immutable
AS $$
    SELECT array_agg(unnest) FROM (SELECT unnest($1)) _ WHERE user_clears_classification($2, $3, $4, user_groups(unnest));
$$;

CREATE OR REPLACE FUNCTION array_set_intersection(anyarray, anyarray) RETURNS anyarray
    LANGUAGE sql immutable
AS $$
    SELECT ARRAY(SELECT unnest($1) INTERSECT SELECT unnest($2));
$$;

CREATE OR REPLACE FUNCTION direct_thread_id(u1 text, u2 text) RETURNS text
    LANGUAGE sql immutable
AS $$
    SELECT CASE WHEN u1 < u2 THEN u1 || '-' || u2 ELSE u2 || '-' || u1 END;
$$;

CREATE OR REPLACE FUNCTION relto_coalition_countries(reltos text[]) RETURNS text[]
    LANGUAGE sql immutable
AS $$
    SELECT array_agg(c) FROM (SELECT unnest(countries) AS c FROM classification_coalition WHERE code = ANY(reltos)) _;
$$;

CREATE OR REPLACE FUNCTION reltos_as_countries(reltos text[]) RETURNS text[]
    LANGUAGE sql immutable
AS $$
    SELECT array_set_union((SELECT array_agg(code) FROM classification_country WHERE code = ANY(reltos)),
        relto_coalition_countries(reltos));
$$;

-- Helper function for users_with_access
CREATE OR REPLACE FUNCTION room_users_with_access(p_id text, room_read_users text[], room_write_users text[], level text, caveats text[], reltos text[]) RETURNS TABLE (read_users text[], write_users text[]) AS
$$
#variable_conflict use_variable

    DECLARE folder_read_users text[];
    DECLARE folder_write_users text[];
    DECLARE read_users text[];
    DECLARE write_users text[];

    BEGIN
        SELECT uwa.read_users, uwa.write_users INTO folder_read_users, folder_write_users FROM
            users_with_access('chat', 'folder', (SELECT root_id FROM chat_room WHERE id::text = p_id)::text) uwa;

        read_users := array_set_intersection(room_read_users, folder_read_users);
        write_users := array_set_union(
            array_set_intersection(room_write_users, array_set_union(folder_read_users, folder_write_users)),
            cleared_users(folder_write_users, level, caveats, reltos));

        RETURN QUERY SELECT read_users, write_users;

    END

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION users_with_access(p_namespace text, p_type text, p_id text) RETURNS TABLE (read_users text[], write_users text[]) AS
$$
#variable_conflict use_variable

    DECLARE read_user_users text[];
    DECLARE write_user_users text[];
    DECLARE none_user_users text[];
    DECLARE read_group_users text[];
    DECLARE write_group_users text[];
    DECLARE none_group_users text[];
    DECLARE read_users text[];
    DECLARE write_users text[];
    DECLARE none_users text[];
    DECLARE level text;
    DECLARE caveats text[];
    DECLARE reltos text[];

    BEGIN
        IF p_namespace = 'chat' AND p_type = 'folder' THEN
            -- Subfolders aren't supported -- they don't have ACLs and their access doesn't cleanly map onto a
            -- list of read and write users; their access is more complex, documented in the roles matrix, and
            -- handled by the chat service.
            IF (SELECT root_id IS NOT NULL FROM chat_folder WHERE id::text = p_id) _ THEN
                RETURN QUERY SELECT NULL::text[], NULL::text[];
                RETURN; -- RETURN QUERY doesn't actually return, just adds a row to the result set; plain RETURN does return.
            END IF;

            IF (SELECT public FROM chat_folder WHERE id::text = p_id) _ THEN
                write_users := (SELECT array_agg(id) FROM users WHERE roles @> ARRAY['chat_admin']);
                read_users := array_remove_many((SELECT array_agg(id) FROM users), write_users);

                RETURN QUERY SELECT read_users, write_users;
                RETURN; -- RETURN QUERY doesn't actually return, just adds a row to the result set; plain RETURN does return.
            END IF;
        END IF;

        read_user_users := user_users_with_access_level(p_namespace, p_type, p_id, 'READ');
        write_user_users := user_users_with_access_level(p_namespace, p_type, p_id, 'WRITE');
        none_user_users := user_users_with_access_level(p_namespace, p_type, p_id, 'NONE');
        read_group_users := group_users_with_access_level(p_namespace, p_type, p_id, 'READ');
        write_group_users := group_users_with_access_level(p_namespace, p_type, p_id, 'WRITE');
        none_group_users := group_users_with_access_level(p_namespace, p_type, p_id, 'NONE');
        none_users := array_set_union(none_user_users, none_group_users);
        write_users := array_remove_many(array_set_union(write_user_users, write_group_users), none_users);
        IF p_namespace = 'chat' AND p_type = 'folder' THEN
            write_users := array_set_union(write_users,
                (SELECT array_agg(id) FROM users WHERE roles @> ARRAY['chat_admin']));
        END IF;
        read_users := array_remove_many(array_remove_many(array_set_union(read_user_users, read_group_users),
            write_users), none_users);
        SELECT c.level, c.caveats, c.reltos INTO level, caveats, reltos FROM object_classification c WHERE
            namespace = p_namespace AND type = p_type AND id = p_id;

        IF p_namespace = 'chat' AND p_type = 'room' AND
          (SELECT value = 'section' FROM chat_value WHERE key = 'nav_mode') _ THEN
            RETURN QUERY SELECT read_users, write_users FROM
                room_users_with_access(p_id, cleared_users(read_users, level, caveats, reltos),
                    cleared_users(write_users, level, caveats, reltos),level, caveats, reltos);
            RETURN; -- RETURN QUERY doesn't actually return, just adds a row to the result set; plain RETURN does return.
        END IF;

        RETURN QUERY SELECT cleared_users(read_users, level, caveats, reltos),
                            cleared_users(write_users, level, caveats, reltos);
    END

$$ LANGUAGE plpgsql;

-- Caller is responsible for determining whether to call based on ObjectRef; only call for types that support/require classification.
-- Function is responsible for determining whether classifications are enabled for the system.
CREATE OR REPLACE FUNCTION valid_classification(level text, caveats text[], reltos text[]) RETURNS boolean AS
$$
#variable_conflict use_variable

    DECLARE system_country text;

    BEGIN
        system_country := (SELECT value FROM classification_value WHERE key = 'system_country');

        RETURN valid_classification_internal(level, caveats, reltos, system_country, relto_coalition_countries(reltos));

    END
$$ LANGUAGE plpgsql;

-- For internal use, with system_country and relto_coalition_countries passed in.  For external (outside postgres)
-- use, use valid_classification().
CREATE OR REPLACE FUNCTION valid_classification_internal(level text, caveats text[], reltos text[], system_country text, relto_coalition_countries text[]) RETURNS boolean AS
$$
#variable_conflict use_variable

    DECLARE pseudo_level boolean;
    DECLARE relto_countries text[];

    BEGIN
        pseudo_level := (SELECT pseudolevel FROM classification_level cl WHERE cl.level = level);
        relto_countries := (SELECT array_agg(code) FROM classification_country WHERE code = ANY(reltos));

        IF system_country IS NULL THEN
            RETURN false; -- Classification config has not been applied yet, so we don't know if they should be enabled or not.
        ELSIF system_country = '' THEN
            RETURN level IS NULL AND array_length(caveats, 1) IS NULL AND array_length(reltos, 1) IS NULL;
        ELSIF pseudo_level THEN
            RETURN array_length(caveats, 1) IS NULL AND array_length(reltos, 1) IS NULL;
        ELSE
            RETURN level IS NULL OR
                ((SELECT array_agg(cl.level) FROM classification_level cl) @> ARRAY[level] IS TRUE) AND
                (array_length(reltos, 1) IS NULL OR
                  ((SELECT array_agg(code) FROM
                      (SELECT code FROM classification_country UNION SELECT code FROM classification_coalition) _)
                      @> reltos) IS TRUE) AND
                (array_length(reltos, 1) IS NULL OR NOT caveats @> '{"DIS-NOFORN"}'::text[] IS TRUE) AND
                (array_length(reltos, 1) IS NULL OR reltos @> ARRAY[system_country] IS TRUE) AND
                (array_length(relto_coalition_countries, 1) IS NULL OR
                    NOT (array_remove(relto_countries, system_country) && relto_coalition_countries));
        END IF;
    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION user_clears_classification(level text, caveats text[], reltos text[], groups text[]) RETURNS boolean AS
$$
#variable_conflict use_variable

    DECLARE system_country text;
    DECLARE rcc text[];
    DECLARE user_reltos text[];
    DECLARE networks_enabled boolean;

    BEGIN
        system_country := (SELECT value FROM classification_value WHERE key = 'system_country');
        user_reltos := (SELECT array_agg(relto) FROM relto_group WHERE group_ = ANY(groups));
        networks_enabled := (SELECT COUNT(group_) > 0 FROM classification_network);
        rcc := relto_coalition_countries(reltos);

        IF system_country = '' THEN
            RETURN level IS NULL AND array_length(caveats, 1) IS NULL AND array_length(reltos, 1) IS NULL;
        ELSE
            RETURN valid_classification_internal(level, caveats, reltos, system_country, rcc) AND
                (array_length(caveats, 1) IS NULL OR
                    (array_cat(
                      (SELECT array_agg(value) FROM dissemination),
                      (SELECT array_agg(caveat) FROM caveat_group WHERE group_=ANY(groups)))
                     @> caveats) IS TRUE) AND
                (SELECT count(code)=1 FROM classification_country WHERE code=ANY(user_reltos)) AND
                ((array_length(reltos, 1) IS NULL AND
                   (groups && (SELECT array_agg(group_) FROM relto_group WHERE relto=system_country)) IS TRUE) OR
                 (SELECT array_agg(relto) FROM relto_group WHERE group_=ANY(groups)) && reltos IS TRUE) AND
                (NOT networks_enabled OR user_network_clears_classification(level, caveats, reltos,
                    rcc, system_country, groups));
        END IF;
    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION user_network_clears_classification(level text, caveats text[], reltos text[], relto_coalition_countries text[], system_country text, p_groups text[]) RETURNS boolean AS
$$
#variable_conflict use_variable

    DECLARE relto_countries text[];
    DECLARE reltos_as_countries text[];

    DECLARE networks_enabled boolean;
    DECLARE req_ident_net_reltos boolean;
    DECLARE network text;
    DECLARE network_level text;
    DECLARE network_caveats text[];
    DECLARE network_reltos text[];

    BEGIN
        relto_countries := (SELECT array_agg(code) FROM classification_country WHERE code = ANY(reltos));
        reltos_as_countries := array_set_union(relto_countries, relto_coalition_countries);

        SELECT ni.networks_enabled, ni.req_ident_net_reltos, ni.name, ni.level, ni.caveats, ni.reltos INTO networks_enabled,
            req_ident_net_reltos, network, network_level, network_caveats, network_reltos FROM
            network_info(p_groups) ni;

        RETURN
                        level IS NULL OR
                        (
                            (classification_level_rank(network_level) >= classification_level_rank(level)) AND
                            (caveats = '{}' OR caveats IS NULL OR (network_caveats @> caveats)) AND
                            (
                                ((reltos = '{}' OR reltos IS NULL) AND network_reltos = ARRAY[system_country]
                                ) OR
                                    (
                                        (req_ident_net_reltos AND network_reltos <@ reltos AND network_reltos @> reltos) OR
                                        (NOT req_ident_net_reltos AND reltos_as_countries @> network_reltos)
                                    )
                            )
                        );

    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleared_objects(system_country text, p_namespace text, p_type text, p_groups text[]) RETURNS TABLE (id text) AS
$$
#variable_conflict use_variable

    DECLARE system_country_group text;
    DECLARE user_country_count int;

    DECLARE networks_enabled boolean;
    DECLARE req_ident_net_reltos boolean;
    DECLARE network text;
    DECLARE network_level text;
    DECLARE network_caveats text[];
    DECLARE network_reltos text[];

    BEGIN
        system_country_group := (SELECT group_ FROM relto_group WHERE relto = system_country);
        user_country_count := (SELECT COUNT(DISTINCT group_) FROM relto_group WHERE p_groups @> ARRAY[group_]);

        SELECT ni.networks_enabled, ni.req_ident_net_reltos, ni.name, ni.level, ni.caveats, ni.reltos INTO networks_enabled,
            req_ident_net_reltos, network, network_level, network_caveats, network_reltos FROM
            network_info(p_groups) ni;

        IF system_country IS NULL THEN

            RETURN QUERY

                SELECT NULL WHERE false; -- Return no rows; waiting for classification config to be applied

        ELSIF user_country_count != 1 THEN

            RETURN QUERY

                SELECT NULL WHERE false; -- Return no rows; admin must fix user to be in exactly one country

        ELSIF networks_enabled AND network IS NULL THEN

            RETURN QUERY

                SELECT NULL WHERE false; -- Return no rows; user must have exactly one network to access

        ELSE

            RETURN QUERY

                SELECT grouped.id FROM

                    (SELECT oc.id,
                            oc.level,
                            oc.caveats,
                            oc.reltos,
                            array_agg(DISTINCT cg.group_) AS caveat_groups,
                            array_agg(DISTINCT rg.group_) AS relto_groups

                        FROM object_classification oc

                        LEFT JOIN caveat_group cg ON cg.caveat = ANY(oc.caveats)
                        LEFT JOIN relto_group rg ON rg.relto = ANY(oc.reltos)

                        WHERE

                            namespace = p_namespace AND
                            type = p_type

                        GROUP BY oc.id, oc.level, oc.caveats, oc.reltos
                    ) grouped

                    WHERE

                        level IS NULL OR
                        (
                            (NOT networks_enabled OR
                                (classification_level_rank(network_level) >= classification_level_rank(level))) AND
                            (caveat_groups = '{NULL}' OR (p_groups @> caveat_groups AND
                                (NOT networks_enabled OR network_caveats @> caveats))) AND
                            (
                                (relto_groups = '{NULL}' AND p_groups @> ARRAY[system_country_group] AND
                                    (NOT networks_enabled OR network_reltos = ARRAY[system_country])
                                ) OR
                                (p_groups && relto_groups AND
                                    (NOT networks_enabled OR
                                        (
                                            (req_ident_net_reltos AND network_reltos <@ reltos AND network_reltos @> reltos) OR
                                            (NOT req_ident_net_reltos AND reltos_as_countries(reltos) @> network_reltos)
                                        )
                                    )
                                )
                            )
                        );

        END IF;

    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION network_info(p_groups text[]) RETURNS TABLE (networks_enabled boolean, req_ident_net_reltos boolean, name text, level text, caveats text[], reltos text[]) AS
$$
#variable_conflict use_variable

    DECLARE net_count integer;

    BEGIN
        networks_enabled := (SELECT COUNT(group_) > 0 FROM classification_network);
        req_ident_net_reltos := (SELECT value = 'true' FROM classification_value WHERE key = 'reqIdenticalNetworkReltos');
        net_count := (SELECT COUNT(group_) FROM classification_network WHERE ARRAY[group_] <@ p_groups);
        name := (SELECT cn.name FROM classification_network cn WHERE ARRAY[group_] <@ p_groups LIMIT 1);

        SELECT cn.level, cn.caveats, cn.reltos INTO level, caveats, reltos FROM
            classification_network cn WHERE cn.name = name;

        IF networks_enabled AND net_count != 1 THEN

            RETURN QUERY SELECT networks_enabled, NULL::boolean, NULL, NULL, NULL::text[], NULL::text[];

        ELSE

            RETURN QUERY

                SELECT networks_enabled, req_ident_net_reltos, name, level, caveats, reltos;

        END IF;

    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION classification_level_rank(p_level text) RETURNS integer AS
$$
    SELECT rank FROM classification_level WHERE p_level = level;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION authorized_objects(p_namespace text, p_type text, p_user text, p_groups text[]) RETURNS TABLE (id text) AS
$$
    BEGIN

        RETURN QUERY SELECT * FROM authorized_objects_admin(p_namespace, p_type, p_user, p_groups, false);

    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION authorized_objects_admin(p_namespace text, p_type text, p_user text, p_groups text[], p_is_admin boolean) RETURNS TABLE (id text) AS
$$
    DECLARE system_country text;

    BEGIN

        system_country := (SELECT value FROM classification_value WHERE key = 'system_country');

        IF p_is_admin THEN

            IF system_country = '' THEN

                RETURN QUERY SELECT id FROM object_acl WHERE namespace = p_namespace AND type = p_type;

            ELSE

                RETURN QUERY SELECT cleared_objects.id FROM cleared_objects(system_country, p_namespace, p_type, p_groups);

            END IF;

        ELSIF system_country = '' THEN

            RETURN QUERY
                SELECT acl.id FROM theia.object_acl acl
                WHERE
                    namespace=p_namespace AND
                    type=p_type AND
                    (users && ARRAY[p_user] OR groups && p_groups)
                    GROUP BY acl.id HAVING MAX(access_level) != 'NONE';

        ELSE

            RETURN QUERY
                SELECT acl.id FROM theia.object_acl acl
                    JOIN cleared_objects(system_country, p_namespace, p_type, p_groups) co ON acl.id=co.id
                WHERE
                    namespace=p_namespace AND
                    type=p_type AND
                    (users && ARRAY[p_user] OR groups && p_groups)
                    GROUP BY acl.id HAVING MAX(access_level) != 'NONE';

        END IF;

    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION folder_admin_ids(p_user text, p_groups text[]) RETURNS TABLE (id text) AS
$$
    DECLARE system_country text;

    BEGIN

        system_country := (SELECT value FROM classification_value WHERE key = 'system_country');

        IF system_country = '' THEN

            RETURN QUERY
                SELECT acl.id FROM theia.object_acl acl
                WHERE
                    namespace='chat' AND
                    type='folder' AND
                    (users && ARRAY[p_user] OR groups && p_groups)
                    GROUP BY acl.id HAVING MAX(access_level) = 'WRITE';

        ELSE

            RETURN QUERY
                SELECT acl.id FROM theia.object_acl acl
                    JOIN cleared_objects(system_country, 'chat', 'folder', p_groups) co ON acl.id=co.id
                WHERE
                    namespace='chat' AND
                    type='folder' AND
                    (users && ARRAY[p_user] OR groups && p_groups)
                    GROUP BY acl.id HAVING MAX(access_level) = 'WRITE';

        END IF;

    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION authorized_chat_messages(p_namespace text, p_user text, p_groups text[]) RETURNS TABLE (id text) AS
$$
    DECLARE system_country TEXT;

    BEGIN
        system_country := (SELECT value FROM classification_value WHERE key = 'system_country');

        IF system_country IS NULL THEN
            RETURN QUERY
              SELECT NULL WHERE NULL IS NOT NULL; -- Just 'SELECT NULL' works, but it feels cleaner to return no rows...
        ELSE
            RETURN QUERY
                SELECT class.id FROM theia.object_classification class WHERE
                    namespace=p_namespace AND
                    (type='room' OR type='direct_thread') AND
                    user_clears_classification(level, caveats, reltos, p_groups)
                    AND class.id IN (
                        SELECT acl.id FROM theia.object_acl acl WHERE
                            namespace=p_namespace AND
                            (type= 'room' OR type='direct_thread')AND
                            (users && ARRAY[p_user] OR groups && p_groups)
                            GROUP BY acl.id HAVING MAX(access_level) != 'NONE'
                        );
        END IF;
    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_classification_suggestions(p_user text, p_groups text[]) RETURNS TABLE (level text, caveats text[], reltos text[]) AS
$$
#variable_conflict use_column
    DECLARE system_country TEXT;

    BEGIN
        system_country := (SELECT value FROM classification_value WHERE key = 'system_country');

        IF system_country IS NULL OR system_country = '' THEN
            RETURN QUERY SELECT NULL, NULL, NULL;
        ELSE
            RETURN QUERY
                SELECT level, caveats, reltos FROM classification_preset WHERE id > 0 AND
                    user_clears_classification(level, caveats, reltos, p_groups);
        END IF;
    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION conversation_has_huddle(p_kind text, p_id text, p_user text)
RETURNS TABLE (has_huddle boolean) AS
$$
    BEGIN
        IF p_kind = 'direct' THEN
            RETURN QUERY
                SELECT EXISTS (SELECT 1 FROM chat_huddle c JOIN video_conference v ON c.huddle_id=v.name WHERE
                    c.kind='direct' AND v.status != 'complete' AND
                    ((c.thread_id = p_id AND c.other_id = p_user) OR (c.thread_id = p_user AND c.other_id = p_id))
                    ORDER BY v.name LIMIT 1);
        ELSIF p_kind = 'room' THEN
            RETURN QUERY
                SELECT EXISTS (SELECT 1 FROM chat_huddle c JOIN video_conference v ON c.huddle_id=v.name WHERE
                    c.kind='room' AND v.status != 'complete' AND c.thread_id = p_id
                    ORDER BY v.name LIMIT 1);
        ELSE
            RETURN QUERY
                SELECT false;
        END IF;
    END
$$ LANGUAGE plpgsql;

-- Changing return signature requires dropping before replacing.
DROP FUNCTION IF EXISTS get_conversations(text, text[]);
DROP FUNCTION IF EXISTS get_conversations(text, text[], text[]);
DROP FUNCTION IF EXISTS get_conversations(text, text[], boolean);

CREATE OR REPLACE FUNCTION get_conversations(p_user text, p_groups text[], p_is_admin boolean)
RETURNS TABLE (kind text, id text, name text, description text, archived boolean, quarantined boolean, xmpp boolean, unread bigint, has_huddle boolean) AS
$$
#variable_conflict use_column
-- variable_conflict use_column allows us to name our output variables and write SQL naturally
    DECLARE nav_mode TEXT;

    BEGIN
        nav_mode := (SELECT value FROM chat_value WHERE key = 'nav_mode');

        RETURN QUERY
            WITH rooms AS (
                SELECT chat_room.id, created_at, name, description, archived, quarantined, xmpp FROM chat_room JOIN
                    authorized_objects_admin('chat', 'room', p_user, p_groups, p_is_admin)
                    auth ON auth.id=chat_room.id::text WHERE nav_mode != 'section'
            )

            SELECT kind, id, name, description, archived, quarantined, xmpp,
              get_unread_count(p_user, p_groups, kind, id) AS unread,
              conversation_has_huddle(kind, id, p_user) AS has_huddle FROM (
                SELECT kind, id, name, description, archived, quarantined, xmpp, max FROM (
                  SELECT kind, r.id, name, description, archived, quarantined, xmpp, max FROM (
                    SELECT 'room' AS kind, id, MAX(max) FROM (
                        SELECT to_id AS id, MAX(sent_at) FROM chat_message
                            WHERE to_kind = 'room' AND to_id IN (SELECT id::text FROM rooms) GROUP BY id

                        UNION

                        SELECT id::text, created_at AS max FROM rooms
                    ) AS _ GROUP BY id
                  ) AS r LEFT JOIN rooms ON r.id = rooms.id::text WHERE p_is_admin OR NOT quarantined

                    UNION

                    SELECT 'irc' AS kind, chat_irc_channel.id::text, channel AS name, NULL AS description, false AS archived,
                        false as quarantined, false as XMPP,
                        CASE WHEN updated > created_at THEN updated ELSE created_at END AS max

                        FROM chat_irc_channel

                        LEFT JOIN chat_irc_last_message lm ON
                            lm.id=chat_irc_channel.id AND lm.uid=p_user

                         WHERE chat_irc_channel.uid = p_user

                    UNION

                    SELECT kind, id, id AS name, NULL AS description, false AS archived, false AS quarantined,
                      false AS xmpp, MAX(sent_at) FROM (
                        SELECT to_kind AS kind, sent_from AS id, sent_at FROM chat_message
                            WHERE to_id = p_user AND to_kind = 'direct'

                        UNION

                        SELECT to_kind AS kind, to_id AS id, sent_at FROM chat_message
                            WHERE sent_from = p_user AND to_kind = 'direct'
                     ) AS _ GROUP BY kind, id

                ) AS _

                ORDER BY max DESC
            ) AS _;
    END
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_unread_count(p_user text, p_kind text, p_oid text);

CREATE OR REPLACE FUNCTION get_unread_count(p_user text, p_groups text[], p_kind text, p_oid text)
RETURNS TABLE (unread bigint) AS
$$
    BEGIN
        IF p_kind = 'direct' THEN
            RETURN QUERY
                SELECT count(id) FROM chat_message WHERE
                    id > (SELECT COALESCE ((SELECT last FROM chat_last_read WHERE
                          uid = p_user AND kind = p_kind AND oid = p_oid), -1)) AND
                    to_kind = p_kind AND
                    ((to_id = p_oid AND sent_from = p_user) OR
                    (to_id = p_user AND sent_from = p_oid));
        ELSE
            RETURN QUERY
                SELECT count(m.id) FROM chat_message m JOIN
                  authorized_objects('chat', p_kind, p_user, p_groups) auth ON auth.id=p_oid WHERE
                    m.id > (SELECT COALESCE ((SELECT last FROM chat_last_read WHERE
                          uid = p_user AND kind = p_kind AND oid = p_oid), -1)) AND
                    to_kind = p_kind AND
                    to_id = p_oid;
        END IF;
    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mark_all_as_read(p_user text, p_groups text[]) RETURNS void AS
$$
    BEGIN

        DELETE FROM chat_last_read WHERE uid=p_user;

        INSERT INTO chat_last_read (uid, kind, oid, last)
          SELECT p_user AS uid, m.to_kind AS kind, m.to_id AS oid, MAX(m.id) AS last FROM chat_message m JOIN
            authorized_objects('chat', m.to_kind, p_user, p_groups) auth ON auth.id=m.to_id::text WHERE
             to_kind='room' OR to_kind='irc' GROUP BY m.to_id, m.to_kind;

        INSERT INTO chat_last_read (uid, kind, oid, last)
          SELECT uid, kind, oid, MAX(id) FROM (SELECT p_user AS uid, to_kind AS kind,
           (CASE WHEN to_id = p_user THEN sent_from ELSE to_id END) AS oid, id FROM chat_message WHERE
           to_kind = 'direct' AND (to_id = p_user OR sent_from = p_user))_ GROUP BY uid, kind, oid;

    END
$$ LANGUAGE plpgsql;

-- Changing return signature requires dropping before replacing.
DROP FUNCTION IF EXISTS get_room_thread(text, bigint, bigint);
DROP FUNCTION IF EXISTS get_room_thread(text, bigint, bigint, bigint);
DROP FUNCTION IF EXISTS get_room_thread(text, bigint, bigint, bigint, text);

CREATE OR REPLACE FUNCTION get_room_thread(rid text, anchor bigint, count bigint, root bigint, direction text)
RETURNS TABLE (id bigint, kind text, sent_from text, sent_at timestamp, body text, uuid uuid, ver bigint, reactions json, translations json, reply_to bigint, delivered bool, read_by text[], latitude float, longitude float, label text, incident_time timestamp, icon_props text, reply_count integer, also_main boolean, orig_lang text, xmpp boolean, panic boolean) AS
$$
#variable_conflict use_column
    BEGIN
    RETURN QUERY
        WITH m AS (
            SELECT id, kind, sent_from, sent_at, body, uuid, ver, reply_to, to_id, delivered, reply_count, also_main, orig_lang, xmpp, panic FROM chat_message WHERE
                to_kind = 'room' AND to_id = rid AND (CASE WHEN direction = 'ASC' THEN id > anchor ELSE id < anchor END) AND
                (
                  (root IS NULL AND (reply_to IS NULL OR also_main))
                      OR
                  root = -1 -- Special value to get all messages for export
                      OR
                  (root IS NOT NULL AND (reply_to = root OR id = root))
                )

                -- With multiple sort expressions, if one of them is empty due to the CASE, then it is ignored.
                -- So with boolean opposite CASEs, exactly one of them will define the order.  Beautifully, that
                -- allows us to get ASC or DESC depending on which CASE statement selected `id` for us.
                ORDER BY (CASE WHEN direction = 'ASC' THEN id END) ASC,
                         (CASE WHEN direction != 'ASC' THEN id END) DESC LIMIT count
        )

        SELECT m.id, m.kind, m.sent_from, m.sent_at, m.body, m.uuid, m.ver, r.reactions, t.translations, m.reply_to, m.delivered, (SELECT array_agg(uid) FROM chat_last_read WHERE kind = 'room' AND oid = m.to_id AND last >= m.id) as read_by, l.latitude, l.longitude, l.label, l.incident_time, l.icon_props, m.reply_count, m.also_main, m.orig_lang, m.xmpp, m.panic FROM
            m
                LEFT JOIN
            (SELECT id, json_agg(json_build_object(uid, kind)) AS reactions FROM
                (SELECT * FROM chat_message_reaction WHERE
                    id = ANY(array(SELECT id FROM m))) _ group by id
            ) r ON r.id = m.id
                LEFT JOIN
            (SELECT id, json_agg(json_build_object(lang, json_build_object('ver', ver, 'text', translation)))
                as translations FROM
                (SELECT * from chat_message_translation WHERE
                    id = ANY(array(SELECT id FROM m))) _ group by id
            ) t ON t.id = m.id
                LEFT JOIN chat_location l on l.id = m.id;
    END
$$ LANGUAGE plpgsql;

-- Changing return signature requires dropping before replacing.
DROP FUNCTION IF EXISTS get_direct_thread(text, text, bigint, bigint);
DROP FUNCTION IF EXISTS get_direct_thread(text, text, bigint, bigint, bigint);
DROP FUNCTION IF EXISTS get_direct_thread(text, text, bigint, bigint, bigint, text);

CREATE OR REPLACE FUNCTION get_direct_thread(uid1 text, uid2 text, anchor bigint, count bigint, root bigint, direction text)
RETURNS TABLE (id bigint, kind text, sent_from text, sent_at timestamp, body text, uuid uuid, ver bigint, reactions json, translations json, reply_to bigint, delivered bool, read_by text[], latitude float, longitude float, label text, incident_time timestamp, icon_props text, reply_count integer, also_main boolean, orig_lang text, xmpp boolean, panic boolean) AS
$$
#variable_conflict use_column
    BEGIN
    RETURN QUERY
        WITH m AS (
            SELECT id, kind, sent_from, sent_at, body, uuid, ver, reply_to, delivered, reply_count, also_main, orig_lang,
              xmpp, panic FROM chat_message WHERE
                to_kind = 'direct' AND
                ((to_id = uid1 AND sent_from = uid2) OR (to_id = uid2 AND sent_from = uid1)) AND
                (CASE WHEN direction = 'ASC' THEN id > anchor ELSE id < anchor END) AND
                (
                  (root IS NULL AND (reply_to IS NULL OR also_main))
                      OR
                  root = -1 -- Special value to get all messages for export
                      OR
                  (root IS NOT NULL AND (reply_to = root OR id = root))
                )

                -- With multiple sort expressions, if one of them is empty due to the CASE, then it is ignored.
                -- So with boolean opposite CASEs, exactly one of them will define the order.  Beautifully, that
                -- allows us to get ASC or DESC depending on which CASE statement selected `id` for us.
                ORDER BY (CASE WHEN direction = 'ASC' THEN id END) ASC,
                         (CASE WHEN direction != 'ASC' THEN id END) DESC LIMIT count
        )

        SELECT m.id, m.kind, m.sent_from, m.sent_at, m.body, m.uuid, m.ver, r.reactions, t.translations, m.reply_to, m.delivered, (SELECT array_agg(uid) FROM chat_last_read WHERE kind = 'direct' AND ((uid = uid1 AND oid = uid2) OR (uid = uid2 AND oid = uid1)) AND last >= m.id) as read_by, l.latitude, l.longitude, l.label, l.incident_time, l.icon_props, m.reply_count, m.also_main, m.orig_lang, m.xmpp, m.panic FROM
            m
                LEFT JOIN
            (SELECT id, json_agg(json_build_object(uid, kind)) AS reactions FROM
                (SELECT * FROM chat_message_reaction WHERE
                    id = ANY(array(SELECT id FROM m))) _ group by id
            ) r ON r.id = m.id
                LEFT JOIN
            (SELECT id, json_agg(json_build_object(lang, json_build_object('ver', ver, 'text', translation)))
                as translations FROM
                (SELECT * from chat_message_translation WHERE
                    id = ANY(array(SELECT id FROM m))) _ group by id
            ) t ON t.id = m.id
                LEFT JOIN chat_location l on l.id = m.id;
    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_journal_id() RETURNS TABLE (jid bigint) AS $$
#variable_conflict use_column
    BEGIN

        IF NOT EXISTS (SELECT jid FROM chat_message_journal LIMIT 1)
        THEN
            INSERT INTO chat_message_journal (mid, event) VALUES (0, '');
        END IF;

        RETURN QUERY SELECT MAX(jid) FROM chat_message_journal;
    END
$$ LANGUAGE plpgsql;

-- Changing return signature requires dropping before replacing.
DROP FUNCTION IF EXISTS journal_sync(text,text[],text[],bigint);

-- Changing return signature requires dropping before replacing.
DROP FUNCTION IF EXISTS journal_sync(text,text[],bigint);

CREATE OR REPLACE FUNCTION journal_sync(p_user text, p_groups text[], p_jid bigint)
RETURNS TABLE (mid bigint, event text, to_kind text, to_id text, sent_from text, uid text, kind text, body text, uuid uuid, sent_at timestamp) AS
$$
#variable_conflict use_column
    BEGIN

    IF NOT EXISTS (SELECT jid FROM chat_message_journal WHERE jid = p_jid)
    THEN
        RETURN QUERY SELECT 0::bigint, 'drop_cache', '', '', '', '', '', '', NULL::uuid, NULL::timestamp;

    ELSE

    RETURN QUERY

    WITH rooms AS (
        SELECT chat_room.id, created_at, name FROM chat_room JOIN
            theia.authorized_objects('chat', 'room', p_user, p_groups)
            auth ON auth.id = chat_room.id::text
    )

    SELECT mid, event, to_kind, to_id, sent_from, uid, kind, body, uuid, sent_at FROM (
        SELECT
            j.mid,
            j.event,
            COALESCE(jd.to_kind, m.to_kind) AS to_kind,
            COALESCE(jd.to_id, m.to_id) AS to_id,
            COALESCE(jd.sent_from, m.sent_from) AS sent_from,
            NULL AS uid,
            CASE WHEN j.event = 'ins_msg' THEN m.kind ELSE NULL END AS kind,
            CASE WHEN j.event = 'ins_msg' OR j.event = 'mod_msg' THEN m.body ELSE NULL END AS body,
            CASE WHEN j.event = 'ins_msg' THEN m.uuid ELSE NULL END AS uuid,
            CASE WHEN j.event = 'ins_msg' THEN m.sent_at ELSE NULL END AS sent_at

            FROM (
                SELECT
                    mid, MIN(event) AS event FROM chat_message_journal WHERE
                        jid > p_jid AND event != 'set_rct' GROUP BY mid
            ) j

            LEFT JOIN (
                SELECT
                    mid, event, to_id, to_kind, sent_from FROM chat_message_journal WHERE
                        event = 'del_msg' AND jid > p_jid
            ) jd ON j.mid = jd.mid

            LEFT JOIN chat_message m ON j.mid = m.id

        UNION

        SELECT
            mid, event, to_kind, to_id, sent_from, j.uid, r.kind, NULL AS body, NULL AS uuid, NULL AS sent_at FROM (
                SELECT DISTINCT mid, uid, event FROM chat_message_journal WHERE
                    jid > p_jid AND event = 'set_rct'
            ) j

            LEFT JOIN chat_message_reaction r ON j.mid = r.id AND j.uid = r.uid

            LEFT JOIN chat_message m ON j.mid = m.id

    ) _ WHERE
        (to_kind = 'direct' AND (to_id = p_user OR sent_from = p_user)) OR
        (to_kind = 'room' AND to_id IN (SELECT id::text FROM rooms));

    END IF;

    END
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS kloud_full_text_query(text);

CREATE OR REPLACE FUNCTION kloud_full_text_query(q text) RETURNS TABLE (key uuid, name text, size bigint, parent_folder_key uuid, tags text[], creator text, created_time timestamp, last_modified_by text, last_modified_time timestamp, mime_type text, lat float, lng float, is_quarantined boolean, version bigint, vector_update_status text) AS $$
#variable_conflict use_column
    DECLARE tsq text;

    BEGIN
        tsq := (select array_to_string(regexp_split_to_array(q, ' '), ' & '));

        RETURN QUERY SELECT m.key, m.name, m.size, m.parent_folder_key, m.tags, m.creator, m.created_time, m.last_modified_by, m.last_modified_time, m.mime_type, m.lat, m.lng, m.is_quarantined, m.version, m.vector_update_status FROM (SELECT key, MAX(score) AS score FROM (SELECT key, ts_rank_cd(ts, to_tsquery('english', tsq)) AS score FROM kloud_item_metadata WHERE ts @@ to_tsquery('english', tsq) UNION (SELECT key, 0.5 AS score FROM kloud_item_metadata WHERE name ILIKE '%' || q || '%')) AS s GROUP BY key) s LEFT JOIN kloud_item_metadata m ON m.key = s.key ORDER BY score DESC;

    END
$$ LANGUAGE plpgsql;

-- Needed for full-text search of tags (we want stemming, etc. for full text search, not just exact tag matches).
-- See https://stackoverflow.com/a/31213069/1427098
CREATE OR REPLACE FUNCTION f_arr_to_text(text[])
  RETURNS text LANGUAGE sql IMMUTABLE AS $$SELECT array_to_string($1, ' ')$$;

CREATE OR REPLACE FUNCTION media_search_trigger() RETURNS trigger AS $$
begin
  new.search :=
    setweight(to_tsvector(coalesce(new.description,'')), 'A');
return new;
end
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_comment_count() RETURNS TRIGGER AS
$$
    BEGIN
        UPDATE theia.media
            SET comment_count = COALESCE(comment_count, 0) + 1
        WHERE id::text = NEW.parent_id;
    RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_comment_count() RETURNS TRIGGER AS
$$
    BEGIN
        UPDATE theia.media
            SET comment_count = COALESCE(comment_count, 0) - 1
        WHERE id::text = OLD.parent_id;
    RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION theia.upsert_trending(time_bucket_r timestamp, class_r text, id_r text)
RETURNS VOID AS $$
    BEGIN
        insert into theia.trending (time_bucket, class, id) values (time_bucket_r::timestamp, class_r, id_r) on conflict do nothing;
        update theia.trending set views = views + 1 where time_bucket = time_bucket_r::timestamp and class = class_r and id = id_r;
    END
$$ LANGUAGE plpgsql;

-- in the set of media/feeds that have multiple tags and the user is subscribed
-- to at least one of those tags, return the tags that the user is not
-- subscribed to.
CREATE OR REPLACE FUNCTION theia.get_suggested_tags(username_r text, limit_r int)
RETURNS SETOF theia.taglist AS $$
    WITH subs AS (
        SELECT tag FROM theia.subscriptions WHERE username = username_r
    ),
    correlated_tags AS (
        SELECT tag_rows FROM (
            SELECT UNNEST(tags) AS tag_rows FROM theia.media
                WHERE tags && (SELECT array_agg(tag) FROM subs)
            UNION ALL
            SELECT UNNEST(tags) AS tag_rows FROM theia.feeds
                WHERE tags && (SELECT array_agg(tag) FROM subs)
        ) a
    )

    SELECT tag_rows AS tag, count(tag_rows) as frequency FROM correlated_tags
    WHERE tag_rows NOT IN (
        SELECT tag from subs
    )
    GROUP BY tag
    ORDER BY frequency DESC
    LIMIT limit_r;
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION theia.get_timeline_base(tag_r text, access_list_r text[])
RETURNS setof theia.post AS $$
    SELECT t.tag, ids.id, t.parent_id, t.username, ids.content, ids.type, ids.attachments, t.create_time
    FROM theia.timeline t
        JOIN theia.timeline_objects ids ON t.type = ids.type and t.parent_id = ids.id
    WHERE tag = tag_r
    AND (array_length(ids.access_list, 1) IS NULL OR ids.access_list && access_list_r);
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION theia.get_user_labeled_media(user_id_r text)
RETURNS setof theia.labeled_media AS $$
    SELECT
        l.label_name,
        -- if artwork is not provided, select the first one
        coalesce((array_agg(l.artwork_id))[1], (array_agg(m.id))[1]) as artwork_id,
        coalesce(json_agg(row_to_json(m.*)) FILTER (WHERE m.id IS NOT NULL), '[]') AS media_data
    FROM theia.labels l
    LEFT JOIN theia.media m ON m.id = l.media_id
    WHERE
        user_id = user_id_r AND
        l.media_id IS NOT NULL
    GROUP BY label_name;
$$ LANGUAGE SQL STABLE;

-- given a time range and pts for a specific feed, return the time offset (in
-- microseconds) for the keyframe that the pts falls in. If the pts value
-- does not fall within the range, this will return a "null" row.  this
-- function is used for syncing the timestamps between what the client player
-- sees (mjpeg) and the server records.
CREATE OR REPLACE FUNCTION theia.get_keyframe_sync_offset(feed_id_r uuid, hls_level_r text, start_time_r timestamp, stop_time_r timestamp, pts_r bigint)
RETURNS theia.keyframe_sync AS $$
        SELECT
            start_time AS keyframe_time,
            (extract(microseconds FROM duration_time) * pts_diff::decimal / duration_pts) AS pts_offset_us
        FROM (
            SELECT
                start_time,
                stop_time - start_time as duration_time,
                pts,
                pts - pts_r AS pts_diff,
                pts - LEAD(pts) over (order by seq asc) AS duration_pts
            FROM theia.chunks
            WHERE feed_id = feed_id_r AND hls_level = hls_level_r AND (
                (start_time BETWEEN start_time_r AND stop_time_r)
                OR
                (stop_time BETWEEN start_time_r AND stop_time_r)
                OR
                (start_time <= start_time_r AND stop_time >= start_time_r)
            )
        ) a
        WHERE pts_diff <= 0 AND pts_diff >= duration_pts;
        -- pts_diff <= 0 because we want the keyframe preceding the requested pts
        -- "negative" pts diff greater than duration because we want pts to fall within "duration"
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION theia.tags_detail(text)
    RETURNS TABLE (
        tag text,
        description text,
        author text,
        create_time timestamp,
        subscriber_count bigint,
        post_count bigint,
        subscribed boolean
    ) AS
$$
    SELECT
        t.tag,
        t.description,
        t.author,
        t.create_time,
        (CASE WHEN s.count IS NULL THEN 0 ELSE s.count END) AS subscriber_count,
        (CASE WHEN posts.count IS NULL THEN 0 ELSE posts.count END) AS post_count,
        (CASE WHEN users.username IS NULL THEN false ELSE true END) AS subscribed
    FROM theia.tags t
        LEFT JOIN (SELECT tag, count(*) FROM theia.subscriptions GROUP BY tag) s ON s.tag=t.tag
        LEFT JOIN (SELECT tag, count(*) FROM theia.social_post_tags GROUP BY tag) posts ON posts.tag=t.tag
        LEFT JOIN (SELECT tag, username FROM theia.subscriptions) users ON users.tag=t.tag AND users.username=$1
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION chat_filenames(bigint) RETURNS text[] IMMUTABLE AS
$$
    SELECT CASE
        WHEN kind='object' THEN
            (SELECT filenames FROM (SELECT id, array_agg(name) AS filenames FROM chat_object_info GROUP BY id) o WHERE o.id=$1)
        WHEN kind='media' THEN
            (SELECT filenames FROM (SELECT id, array_agg(name) AS filenames FROM chat_media_info GROUP BY id) i WHERE i.id=$1)
        ELSE
            '{}'
        END AS filenames
    FROM chat_message WHERE chat_message.id=$1;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS chat_full_text_query(text);

CREATE OR REPLACE FUNCTION chat_full_text_query(p_q text, p_user text, p_groups text[]) RETURNS TABLE (id bigint, to_id text, to_kind text, sent_from text, sent_at timestamp, kind text, body text, uuid uuid, ver bigint, reply_to bigint, delivered boolean, score real) AS $$
#variable_conflict use_column
    BEGIN

    RETURN QUERY SELECT q.id, to_id, to_kind, sent_from, sent_at, kind, body, uuid, ver, reply_to, delivered, score FROM
        chat_full_text_query_internal(p_q, 'room') q JOIN
        authorized_objects('chat', 'room', p_user, p_groups) auth ON auth.id = q.to_id

    UNION

    SELECT q.id, to_id, to_kind, sent_from, sent_at, kind, body, uuid, ver, reply_to, delivered, score FROM
        chat_full_text_query_internal(p_q, 'direct') q JOIN
        authorized_objects('chat', 'direct_thread', p_user, p_groups) auth ON auth.id = direct_thread_id(q.to_id, q.sent_from);

    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION chat_full_text_query_internal(q text, p_kind text) RETURNS TABLE (id bigint, to_id text, to_kind text, sent_from text, sent_at timestamp, kind text, body text, uuid uuid, ver bigint, reply_to bigint, delivered boolean, score real) AS $$
#variable_conflict use_column
    DECLARE tsq text;

    BEGIN
        tsq := (select array_to_string(regexp_split_to_array(q, ' '), ' & '));

        RETURN QUERY SELECT m.id, to_id, to_kind, sent_from, sent_at, kind, body, uuid, ver, reply_to, delivered, score FROM
            (SELECT id, MAX(score) AS score FROM
                (SELECT
                    id, ts_rank_cd(ts, to_tsquery('english', tsq)) AS score FROM chat_message WHERE
                        ts @@ to_tsquery('english', tsq) AND to_kind = p_kind

                    UNION

                    (SELECT i.id, 0.5 AS score FROM chat_media_info i JOIN chat_message m ON m.id = i.id WHERE
                        name ILIKE '%' || q || '%' AND to_kind = p_kind)

                    UNION

                    (SELECT i.id, 0.5 AS score FROM chat_object_info i JOIN chat_message m ON m.id = i.id WHERE
                        name ILIKE '%' || q || '%' AND to_kind = p_kind)

                ) AS s GROUP BY id) s LEFT JOIN chat_message m ON m.id = s.id ORDER BY score DESC;
    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION chat_object_text(bigint) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
    SELECT string_agg(full_text, e'\n') FROM chat_object_info WHERE id=$1
$$;

CREATE OR REPLACE FUNCTION chat_search_index_trigger() RETURNS trigger AS $$
BEGIN

    UPDATE chat_message SET ts =
        setweight(to_tsvector('english', coalesce(body, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(f_arr_to_text(chat_filenames(id)), '')), 'B') ||
        setweight(to_tsvector('english', coalesce(chat_object_text(id), '')), 'C');

RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- Takes an array of four float coordinates in this order: xmin, ymin, xmax, ymax
CREATE OR REPLACE FUNCTION f_arr_to_geo(float[])
  RETURNS geometry LANGUAGE sql IMMUTABLE AS $$SELECT ST_MakeEnvelope($1[1], $1[2], $1[3], $1[4], 4326)$$;

-- From https://stackoverflow.com/a/41405177/1427098
CREATE OR REPLACE FUNCTION unnest_2d_1d(ANYARRAY, OUT a ANYARRAY)
  RETURNS SETOF ANYARRAY
  LANGUAGE plpgsql IMMUTABLE STRICT AS
$func$
BEGIN
   FOREACH a SLICE 1 IN ARRAY $1 LOOP
      RETURN NEXT;
   END LOOP;
END
$func$;

CREATE OR REPLACE FUNCTION unarchived_chat_room_last_activity() RETURNS TABLE (id text, last_activity timestamp) AS $$
#variable_conflict use_variable

    BEGIN
        RETURN QUERY
            SELECT chat_room.id::text, CASE WHEN max IS NOT NULL THEN max ELSE created_at END AS last_activity
            FROM (SELECT to_id, max(sent_at) FROM chat_message WHERE to_kind = 'room' GROUP BY to_id) _
            RIGHT JOIN chat_room ON chat_room.id::text = to_id
            WHERE NOT archived;
    END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = current_timestamp;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_vector_status()
RETURNS TRIGGER AS $$
BEGIN
    -- exit early if irrelevant
    IF (NEW.is_quarantined = true) THEN
        NEW.vector_update_status = 'DISABLED';
        NEW.last_vector_update = NOW();
        RETURN NEW;
    END IF;

    IF (NEW.full_text IS NULL OR TRIM(NEW.full_text) = '') THEN
        NEW.vector_update_status = 'SKIP';
        NEW.last_vector_update = NOW();
        RETURN NEW;
    END IF;

    -- determine if vector needs to be updated
    IF TG_OP = 'INSERT' OR (
        TG_OP = 'UPDATE' AND (
            NEW.name IS DISTINCT FROM OLD.name OR
            NEW.lat IS DISTINCT FROM OLD.lat OR
            NEW.lng IS DISTINCT FROM OLD.lng OR
            NEW.tags IS DISTINCT FROM OLD.tags OR
            NEW.full_text IS DISTINCT FROM OLD.full_text
        )
    ) THEN
        NEW.vector_update_status = 'NEEDS_UPDATE';
        -- set NULL to indicate it hasn't been processed
        NEW.last_vector_update = NULL;

        -- invalidate corresponding embeddings in the other table
        UPDATE theia.kloud_item_embeddings
        SET
          is_current = FALSE
        WHERE
          item_key = NEW.key;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

set check_function_bodies = on;
