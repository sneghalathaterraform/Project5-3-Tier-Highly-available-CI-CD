<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.List, com.libraryhub.BookSearchServlet.Book" %>
<%
    String query        = (String)     request.getAttribute("query");
    List<Book> results  = (List<Book>) request.getAttribute("results");
    String error        = (String)     request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>LibraryHub – Book Search</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<nav class="navbar navbar-dark bg-success px-4">
  <span class="navbar-brand fw-bold">📚 LibraryHub</span>
  <span class="text-white-50 small">Part 2 – EC2 ALB + ASG + Java 21/Tomcat + RDS</span>
</nav>
<div class="container py-5">
  <div class="row justify-content-center">
    <div class="col-md-6">

      <!-- Search box -->
      <div class="card border-0 shadow-sm mb-4">
        <div class="card-body p-4">
          <form method="GET" action="search">
            <div class="input-group">
              <input type="text" name="q" class="form-control form-control-lg"
                     placeholder="Search by title or author…"
                     value="<%= query != null ? query : "" %>" autofocus>
              <button class="btn btn-success px-4" type="submit">Search</button>
            </div>
          </form>
        </div>
      </div>

      <% if (error != null) { %>
        <div class="alert alert-danger"><%= error %></div>
      <% } %>

      <% if (query != null && !query.isBlank()) { %>
        <% if (results == null || results.isEmpty()) { %>
          <div class="alert alert-warning text-center">
            No books found for <strong><%= query %></strong>.
          </div>
        <% } else { %>
          <div class="card border-0 shadow-sm">
            <div class="card-header bg-success text-white fw-semibold">
              <%= results.size() %> result<%= results.size() > 1 ? "s" : "" %>
              for &ldquo;<%= query %>&rdquo;
            </div>
            <ul class="list-group list-group-flush">
              <% for (Book b : results) { %>
              <li class="list-group-item d-flex justify-content-between align-items-center py-3">
                <div>
                  <div class="fw-semibold"><%= b.title() %></div>
                  <small class="text-muted"><%= b.author() %></small>
                </div>
                <% if (b.availableCopies() > 0) { %>
                  <span class="badge bg-success px-3 py-2">✅ Available</span>
                <% } else { %>
                  <span class="badge bg-danger px-3 py-2">❌ Not Available</span>
                <% } %>
              </li>
              <% } %>
            </ul>
          </div>
        <% } %>
      <% } %>

    </div>
  </div>
</div>
</body>
</html>
