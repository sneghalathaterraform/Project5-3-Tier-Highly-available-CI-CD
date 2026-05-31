package com.libraryhub;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DB {

    public static Connection getConnection() throws SQLException {

        String host = System.getenv("DB_HOST");
        String name = System.getenv("DB_NAME");
        String user = System.getenv("DB_USER");
        String pass = System.getenv("DB_PASSWORD");

        // fallbacks
        if (host == null || host.isBlank()) host = "127.0.0.1";
        if (name == null || name.isBlank()) name = "libraryhub";
        if (user == null || user.isBlank()) user = "admin";
        if (pass == null || pass.isBlank()) pass = "";

        String url = "jdbc:mysql://" + host + "/" + name
                   + "?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";

        return DriverManager.getConnection(url, user, pass);
    }
}