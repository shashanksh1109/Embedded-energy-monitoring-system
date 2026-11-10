package com.energy.config;

import com.energy.security.TenantContext;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.DelegatingDataSource;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * TenantDataSourceConfig - tells PostgreSQL which organization each
 * database connection is working for.
 *
 * Every time Spring/Hibernate takes a connection from the pool, we run:
 *
 *     SELECT set_config('app.current_org', '<org uuid>', false)
 *
 * The row-level security policies in schema.sql compare every row's org_id
 * with this setting, so queries only ever see the current organization.
 *
 * It is set on EVERY checkout (never only "if missing"), so a pooled
 * connection can never carry the previous request's organization into the
 * next one.
 */
@Configuration
public class TenantDataSourceConfig {

    /**
     * Wraps the application's DataSource (Hikari's connection pool) in
     * TenantAwareDataSource as soon as Spring creates it.
     * "static" is the recommended form for BeanPostProcessor beans.
     */
    @Bean
    public static BeanPostProcessor tenantDataSourceWrapper() {
        return new BeanPostProcessor() {
            @Override
            public Object postProcessAfterInitialization(Object bean, String beanName) {
                if (bean instanceof DataSource dataSource
                        && !(bean instanceof TenantAwareDataSource)) {
                    return new TenantAwareDataSource(dataSource);
                }
                return bean;
            }
        };
    }

    /** A DataSource that sets app.current_org on every connection it hands out. */
    static class TenantAwareDataSource extends DelegatingDataSource {

        TenantAwareDataSource(DataSource target) {
            super(target);
        }

        @Override
        public Connection getConnection() throws SQLException {
            return applyTenant(super.getConnection());
        }

        @Override
        public Connection getConnection(String username, String password) throws SQLException {
            return applyTenant(super.getConnection(username, password));
        }

        private Connection applyTenant(Connection connection) throws SQLException {
            try (PreparedStatement ps = connection.prepareStatement(
                    "SELECT set_config('app.current_org', ?, false)")) {
                ps.setString(1, TenantContext.get().toString());
                ps.execute();
            } catch (SQLException e) {
                connection.close();          // never hand out a connection in an unknown state
                throw e;
            }
            return connection;
        }
    }
}