<?php
$modeCli = isset($argv[0]) && is_file($argv[0]);
ini_set('display_errors', $modeCli ? 1 : 0);