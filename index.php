<html>
<head>
    <title>Varnish</title>
</head>
<body>

<?php

// to test, just access http://localhost?token, where token can be no-cache, age, cookie or esi

$token = false;
if (isset($_GET['token'])) {
    $token = $_GET['token'] ;
}

switch ($token) {
    case "no-cache":
        header('Cache Control: no-cache, no-store, must-revalidate, post-check=0, pre-check=0'); // HTTP 1.1.
        header('Pragma: no-cache'); // HTTP 1.0.
        header('Expires: 0'); // Proxies.
        break;
    case "age":
        headers_for_page_cache(15);
        break;
    case "cookie":
        setcookie("TestCookie", "test", time()+60);
        break;
    case "esi":
        header('esi-enabled: 1');
        break;
}
echo "Token: " . $token . "<br />";

echo "<img src='index.gif' /><br /><br /><br />";


echo 'This comes from esi: <esi:include src="/time.php" />';

function headers_for_page_cache($cache_length=600){
    $cache_expire_date = gmdate("D, d M Y H:i:s", time() + $cache_length);
    header("Expires: $cache_expire_date");
    header("Pragma: cache");
    header("Cache-Control: max-age=$cache_length, s-maxage=$cache_length");
    header("User-Cache-Control: max-age=$cache_length");
}

echo "<br /><br /><br />";
?>
</body>
</html>
