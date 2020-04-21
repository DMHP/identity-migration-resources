package org.wso2.carbon.is.migration.service.v5100.migrator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.wso2.carbon.identity.core.migrate.MigrationClientException;
import org.wso2.carbon.is.migration.service.Migrator;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class ScopeDataMigrator extends Migrator {

    private static final Logger log = LoggerFactory.getLogger(ScopeDataMigrator.class);

    private static final String ADD_SCOPE_TYPE_COLUMN = "ALTER TABLE IDN_OAUTH2_SCOPE ADD COLUMN " +
            "SCOPE_TYPE VARCHAR(255) NOT NULL DEFAULT 'OAUTH2'";

    public static final String RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_MYSQL = "SELECT SCOPE_TYPE " +
            "FROM IDN_OAUTH2_SCOPE LIMIT 1";
    public static final String RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_DB2SQL = "SELECT SCOPE_TYPE " +
            "FROM IDN_OAUTH2_SCOPE FETCH FIRST 1 ROWS ONLY";
    public static final String RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_MSSQL = "SELECT TOP 1 SCOPE_TYPE " +
            "FROM IDN_OAUTH2_SCOPE";
    public static final String RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_INFORMIX = "SELECT FIRST 1 SCOPE_TYPE " +
            "FROM IDN_OAUTH2_SCOPE";
    public static final String RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_ORACLE = "SELECT SCOPE_TYPE " +
            "FROM IDN_OAUTH2_SCOPE WHERE ROWNUM < 2";

    private static final String SCOPE_TYPE_COLUMN = "SCOPE_TYPE";

    @Override
    public void dryRun() throws MigrationClientException {

        log.info("Dry run capability not implemented in {} migrator.", this.getClass().getName());
    }

    @Override
    public void migrate() throws MigrationClientException {

        boolean isScopeTypeColumnExists;
        try (Connection connection = getDataSource().getConnection()) {
            connection.setAutoCommit(false);
            isScopeTypeColumnExists = isScopeTypeColumnExists(connection);
            connection.rollback();
        } catch (SQLException ex) {
            throw new MigrationClientException("Error occurred while creating the SCOPE_TYPE column.", ex);
        }

        if (!isScopeTypeColumnExists) {
            try (Connection connection = getDataSource().getConnection()) {
                try {
                    connection.setAutoCommit(false);
                    createScopeTypeColumn(connection);
                    connection.commit();
                } catch (SQLException ex) {
                    connection.rollback();
                    throw ex;
                }
            } catch (SQLException ex) {
                throw new MigrationClientException("Error occurred while creating the SCOPE_TYPE column.", ex);
            }
        }
    }

    private void createScopeTypeColumn(Connection connection) throws SQLException {

        try (PreparedStatement preparedStatement = connection.prepareStatement(ADD_SCOPE_TYPE_COLUMN)) {
            preparedStatement.executeUpdate();
        }
    }

    private boolean isScopeTypeColumnExists(Connection connection) throws SQLException {

        String sql;
        boolean isScopeTypeColumnExists;
        if (connection.getMetaData().getDriverName().contains("MySQL") || connection.getMetaData().getDriverName()
                .contains("H2")) {
            sql = RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_MYSQL;
        } else if (connection.getMetaData().getDatabaseProductName().contains("DB2")) {
            sql = RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_DB2SQL;
        } else if (connection.getMetaData().getDriverName().contains("MS SQL") || connection.getMetaData()
                .getDriverName().contains("Microsoft")) {
            sql = RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_MSSQL;
        } else if (connection.getMetaData().getDriverName().contains("PostgreSQL")) {
            sql = RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_MYSQL;
        } else if (connection.getMetaData().getDriverName().contains("Informix")) {
            // Driver name = "IBM Informix JDBC Driver for IBM Informix Dynamic Server"
            sql = RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_INFORMIX;
        } else {
            sql = RETRIEVE_IDN_OAUTH2_SCOPE_TABLE_ORACLE;
        }

        try (PreparedStatement preparedStatement = connection.prepareStatement(sql)) {
            try {
                ResultSet resultSet = preparedStatement.executeQuery();
                if (resultSet != null) {
                    resultSet.findColumn(SCOPE_TYPE_COLUMN);
                    isScopeTypeColumnExists = true;
                } else {
                    isScopeTypeColumnExists = false;
                }
            } catch (SQLException e) {
                isScopeTypeColumnExists = false;
            }
        } catch (SQLException e) {
            isScopeTypeColumnExists = false;
        }
        return isScopeTypeColumnExists;
    }
}
