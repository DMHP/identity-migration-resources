IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_OAUTH2_AUTHZ_CODE_SCOPE]') AND TYPE IN (N'U'))
CREATE TABLE IDN_OAUTH2_AUTHZ_CODE_SCOPE (
    CODE_ID VARCHAR(255),
    SCOPE VARCHAR(60),
    TENANT_ID INTEGER DEFAULT -1,
    PRIMARY KEY (CODE_ID, SCOPE),
    FOREIGN KEY (CODE_ID) REFERENCES IDN_OAUTH2_AUTHORIZATION_CODE(CODE_ID) ON DELETE CASCADE
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_OAUTH2_TOKEN_BINDING]') AND TYPE IN (N'U'))
CREATE TABLE IDN_OAUTH2_TOKEN_BINDING (
    TOKEN_ID VARCHAR(255),
    TOKEN_BINDING_TYPE VARCHAR(32),
    TOKEN_BINDING_REF VARCHAR(32),
    TOKEN_BINDING_VALUE VARCHAR(1024),
    TENANT_ID INTEGER DEFAULT -1,
    PRIMARY KEY (TOKEN_ID),
    FOREIGN KEY (TOKEN_ID) REFERENCES IDN_OAUTH2_ACCESS_TOKEN(TOKEN_ID) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_FED_AUTH_SESSION_MAPPING]') AND TYPE IN (N'U'))
CREATE TABLE IDN_FED_AUTH_SESSION_MAPPING (
    IDP_SESSION_ID VARCHAR(255) NOT NULL,
    SESSION_ID VARCHAR(255) NOT NULL,
    IDP_NAME VARCHAR(255) NOT NULL,
    AUTHENTICATOR_ID VARCHAR(255),
    PROTOCOL_TYPE VARCHAR(255),
    TIME_CREATED DATETIME NOT NULL,
    PRIMARY KEY (IDP_SESSION_ID)
);

IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_OAUTH2_CIBA_AUTH_CODE]') AND TYPE IN (N'U'))
CREATE TABLE IDN_OAUTH2_CIBA_AUTH_CODE (
    AUTH_CODE_KEY CHAR (36),
    AUTH_REQ_ID CHAR (36),
    ISSUED_TIME DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSUMER_KEY VARCHAR(255),
    LAST_POLLED_TIME DATETIME NOT NULL,
    POLLING_INTERVAL INTEGER,
    EXPIRES_IN  INTEGER,
    AUTHENTICATED_USER_NAME VARCHAR(255),
    USER_STORE_DOMAIN VARCHAR(100),
    TENANT_ID INTEGER,
    AUTH_REQ_STATUS VARCHAR(100) DEFAULT ('REQUESTED'),
    IDP_ID INTEGER,
    UNIQUE(AUTH_REQ_ID),
    PRIMARY KEY (AUTH_CODE_KEY),
    FOREIGN KEY (CONSUMER_KEY) REFERENCES IDN_OAUTH_CONSUMER_APPS(CONSUMER_KEY) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_OAUTH2_CIBA_REQUEST_SCOPES]') AND TYPE IN (N'U'))
CREATE TABLE IDN_OAUTH2_CIBA_REQUEST_SCOPES (
    AUTH_CODE_KEY CHAR(36),
    SCOPE VARCHAR(255),
    FOREIGN KEY (AUTH_CODE_KEY) REFERENCES IDN_OAUTH2_CIBA_AUTH_CODE(AUTH_CODE_KEY) ON DELETE CASCADE
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_OAUTH2_DEVICE_FLOW]') AND TYPE IN (N'U'))
CREATE TABLE IDN_OAUTH2_DEVICE_FLOW (
    CODE_ID VARCHAR(255),
    DEVICE_CODE VARCHAR(255),
    USER_CODE VARCHAR(25),
    CONSUMER_KEY_ID INTEGER,
    LAST_POLL_TIME DATETIME NOT NULL,
    EXPIRY_TIME DATETIME NOT NULL,
    TIME_CREATED DATETIME NOT NULL,
    POLL_TIME BIGINT,
    STATUS VARCHAR(25) DEFAULT 'PENDING',
    AUTHZ_USER VARCHAR(100),
    TENANT_ID INTEGER,
    USER_DOMAIN VARCHAR(50),
    IDP_ID INTEGER,
    PRIMARY KEY (DEVICE_CODE),
    UNIQUE (CODE_ID),
    FOREIGN KEY (CONSUMER_KEY_ID) REFERENCES IDN_OAUTH_CONSUMER_APPS(ID) ON DELETE CASCADE
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_OAUTH2_DEVICE_FLOW_SCOPES]') AND TYPE IN (N'U'))
CREATE TABLE IDN_OAUTH2_DEVICE_FLOW_SCOPES (
    ID INTEGER NOT NULL IDENTITY,
    SCOPE_ID VARCHAR(255),
    SCOPE VARCHAR(255),
    PRIMARY KEY (ID),
    FOREIGN KEY (SCOPE_ID) REFERENCES IDN_OAUTH2_DEVICE_FLOW(CODE_ID) ON DELETE CASCADE
);

ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN ADD TOKEN_BINDING_REF VARCHAR(32) DEFAULT 'NONE';

ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN DROP CONSTRAINT CON_APP_KEY;

ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN	ADD CONSTRAINT CON_APP_KEY UNIQUE (CONSUMER_KEY_ID,AUTHZ_USER,TENANT_ID,USER_DOMAIN,USER_TYPE,TOKEN_SCOPE_HASH,TOKEN_STATE,TOKEN_STATE_ID,IDP_ID,TOKEN_BINDING_REF);

ALTER TABLE IDN_ASSOCIATED_ID ADD ASSOCIATION_ID CHAR(36) NOT NULL DEFAULT LOWER(NEWID());

ALTER TABLE SP_APP
    ADD UUID CHAR(36) DEFAULT LOWER(NEWID()) NOT NULL,
        IMAGE_URL VARCHAR(1024),
        ACCESS_URL VARCHAR(1024),
        IS_DISCOVERABLE CHAR(1) DEFAULT '0',
        CONSTRAINT APPLICATION_UUID_CONSTRAINT UNIQUE(UUID);

ALTER TABLE IDP
    ADD IMAGE_URL VARCHAR(1024),
        UUID CHAR(36) DEFAULT LOWER(NEWID()) NOT NULL,
        UNIQUE(UUID);

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_CONFIG_FILE]') AND TYPE IN (N'U'))
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'IDN_CONFIG_FILE' AND COLUMN_NAME = 'NAME')
ALTER TABLE IDN_CONFIG_FILE ADD NAME VARCHAR(255) NULL;

ALTER TABLE FIDO2_DEVICE_STORE
    ADD  DISPLAY_NAME VARCHAR(255),
        IS_USERNAMELESS_SUPPORTED CHAR(1) DEFAULT '0';

ALTER TABLE IDN_OAUTH2_SCOPE_BINDING ALTER COLUMN SCOPE_BINDING VARCHAR(255) NOT NULL;

ALTER TABLE IDN_OAUTH2_SCOPE_BINDING
    ADD BINDING_TYPE VARCHAR(255) NOT NULL DEFAULT 'DEFAULT',
    UNIQUE (SCOPE_ID, SCOPE_BINDING, BINDING_TYPE);

-- Related to Scope Management --
DROP INDEX IDX_SC_N_TID ON IDN_OAUTH2_SCOPE;

ALTER TABLE IDN_OAUTH2_SCOPE
    ADD SCOPE_TYPE VARCHAR(255) NOT NULL DEFAULT 'OAUTH2'
    UNIQUE(NAME, TENANT_ID);

CREATE TABLE IDN_OIDC_SCOPE_CLAIM_MAPPING_NEW (
    ID INTEGER IDENTITY,
    SCOPE_ID INTEGER NOT NULL,
    EXTERNAL_CLAIM_ID INTEGER NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (SCOPE_ID) REFERENCES  IDN_OAUTH2_SCOPE(SCOPE_ID) ON DELETE CASCADE,
    FOREIGN KEY (EXTERNAL_CLAIM_ID) REFERENCES  IDN_CLAIM(ID) ON DELETE CASCADE,
    UNIQUE (SCOPE_ID, EXTERNAL_CLAIM_ID)
);

DROP PROCEDURE IF EXISTS OIDC_SCOPE_DATA_MIGRATE_PROCEDURE;

CREATE PROCEDURE OIDC_SCOPE_DATA_MIGRATE_PROCEDURE
AS
BEGIN
    DECLARE @oidc_scope_count INT
    DECLARE @row_offset INT
    DECLARE @oauth_scope_id INT
    DECLARE @oidc_scope_id INT
    SET @row_offset = 0
    SET @oauth_scope_id = 0
    SET @oidc_scope_id = 0
    SET @oidc_scope_count = (SELECT COUNT(*) FROM IDN_OIDC_SCOPE)
    WHILE @row_offset < @oidc_scope_count
    BEGIN
        SET @oidc_scope_id = (SELECT ID FROM IDN_OIDC_SCOPE ORDER BY ID OFFSET @row_offset ROWS FETCH NEXT 1 ROWS ONLY)
        INSERT INTO IDN_OAUTH2_SCOPE (NAME, DISPLAY_NAME, TENANT_ID, SCOPE_TYPE) SELECT NAME, NAME, TENANT_ID, 'OIDC' FROM IDN_OIDC_SCOPE ORDER BY ID OFFSET @row_offset ROWS FETCH NEXT 1 ROWS ONLY
        SET @oauth_scope_id = (SELECT SCOPE_IDENTITY())
        INSERT INTO IDN_OIDC_SCOPE_CLAIM_MAPPING_NEW (SCOPE_ID, EXTERNAL_CLAIM_ID) SELECT @oauth_scope_id, EXTERNAL_CLAIM_ID FROM IDN_OIDC_SCOPE_CLAIM_MAPPING WHERE SCOPE_ID = @oidc_scope_id
        SET @row_offset = @row_offset + 1
	END
END;

EXEC OIDC_SCOPE_DATA_MIGRATE_PROCEDURE;

DROP PROCEDURE IF EXISTS OIDC_SCOPE_DATA_MIGRATE_PROCEDURE;

DROP TABLE IDN_OIDC_SCOPE_CLAIM_MAPPING;

EXEC sp_rename IDN_OIDC_SCOPE_CLAIM_MAPPING_NEW, IDN_OIDC_SCOPE_CLAIM_MAPPING;

DROP TABLE IDN_OIDC_SCOPE;

CREATE INDEX IDX_IDN_AUTH_BIND ON IDN_OAUTH2_TOKEN_BINDING (TOKEN_BINDING_REF);

CREATE INDEX IDX_AI_DN_UN_AI ON IDN_ASSOCIATED_ID(DOMAIN_NAME, USER_NAME, ASSOCIATION_ID);

CREATE INDEX IDX_AT_CKID_AU_TID_UD_TSH_TS ON IDN_OAUTH2_ACCESS_TOKEN(CONSUMER_KEY_ID, AUTHZ_USER, TENANT_ID, USER_DOMAIN, TOKEN_SCOPE_HASH, TOKEN_STATE);

CREATE INDEX IDX_FEDERATED_AUTH_SESSION_ID ON IDN_FED_AUTH_SESSION_MAPPING (SESSION_ID);

TRUNCATE TABLE IDN_AUTH_SESSION_APP_INFO;

TRUNCATE TABLE IDN_AUTH_SESSION_STORE;

TRUNCATE TABLE IDN_AUTH_SESSION_META_DATA;

TRUNCATE TABLE IDN_AUTH_USER;

TRUNCATE TABLE IDN_AUTH_USER_SESSION_MAPPING;
