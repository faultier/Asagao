<!DOCTYPE html>
<html>
    <head>
        <title><%= $title %></title>
        <meta name="generator" content="Plack <%= $PLACK_VERSION %>, Asagao <%= $ASAGAO_VERSION %>">
        <meta name="keywords" content="faultier,Plack,Asagao">
        <meta name="author" content="faultier">
        <link rel="stylesheet" type="text/css" href="<%= $base_path %>/css/common.css">
    </head>
    <body>
        <div id="main">
            <h1><%= $site_title %></h1>
            <% block content => sub {} %>
        </div>
    </body>
</html>
