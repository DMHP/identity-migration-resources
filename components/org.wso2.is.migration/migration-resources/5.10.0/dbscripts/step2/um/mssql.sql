ALTER TABLE UM_USER
    ADD UM_USER_ID CHAR(36) DEFAULT LOWER(NEWID()) NOT NULL,
    UNIQUE(UM_USER_ID);
