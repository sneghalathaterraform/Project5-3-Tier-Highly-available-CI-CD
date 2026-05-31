package com.libraryhub;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
public class BookSearchServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Health check endpoint – called by ALB and Route 53
        if ("/health".equals(req.getServletPath())) {
            resp.setContentType("application/json");
            try (Connection c = DB.getConnection();
                 Statement st = c.createStatement()) {
                st.execute("SELECT 1");
                resp.setStatus(200);
                resp.getWriter().write("{\"status\":\"ok\",\"part\":\"2\"}");
            } catch (SQLException e) {
    resp.setStatus(503);
    resp.getWriter().write("{\"status\":\"db_error\",\"error\":\"" 
        + e.getMessage().replace("\"","'").replace("\n"," ") + "\"}");
}
            return;
        }

        // Book search
        String query = req.getParameter("q");
        List<Book> results = new ArrayList<>();

        if (query != null && !query.isBlank()) {
            String sql = "SELECT title, author, available_copies " +
                         "FROM books WHERE title LIKE ? OR author LIKE ? " +
                         "ORDER BY title LIMIT 10";
            try (Connection c  = DB.getConnection();
                 PreparedStatement ps = c.prepareStatement(sql)) {
                String like = "%" + query.trim() + "%";
                ps.setString(1, like);
                ps.setString(2, like);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        results.add(new Book(
                            rs.getString("title"),
                            rs.getString("author"),
                            rs.getInt("available_copies")
                        ));
                    }
                }
            } catch (SQLException e) {
                req.setAttribute("error", "Database error: " + e.getMessage());
            }
        }

        req.setAttribute("query",   query);
        req.setAttribute("results", results);
        req.getRequestDispatcher("/WEB-INF/search.jsp").forward(req, resp);
    }

    public record Book(String title, String author, int availableCopies) {}
}
