<?php
echo "Autorizado<br>";

$ip = $_SERVER['REMOTE_ADDR'];
echo "Client IP: " . htmlspecialchars($ip, ENT_QUOTES, 'UTF-8');

$httpHost = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'Unknown Host';

// Output the HTTP host
echo "<br>HTTP Host: " . htmlspecialchars($httpHost, ENT_QUOTES, 'UTF-8');
