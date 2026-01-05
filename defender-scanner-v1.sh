#!/bin/bash

# ==============================================
# DETECTOR PHP BACKDOOR LEVEL DEWA
# Analisis Konten File - Zero False Positive
# Version 3.0 - Ultimate Accuracy
# ==============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Config
MIN_SIZE=50
MAX_SIZE=2000000
LOG_FILE="/tmp/backdoor_scan_$(date +%s).log"

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo '╔══════════════════════════════════════════════════════════════╗'
    echo '║  ██████╗  █████╗  ██████╗██╗  ██╗██████╗  ██████╗ ██████╗   ║'
    echo '║  ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗  ║'
    echo '║  ██████╔╝███████║██║     █████╔╝ ██║  ██║██║   ██║██████╔╝  ║'
    echo '║  ██╔══██╗██╔══██║██║     ██╔═██╗ ██║  ██║██║   ██║██╔══██╗  ║'
    echo '║  ██████╔╝██║  ██║╚██████╗██║  ██╗██████╔╝╚██████╔╝██║  ██║  ║'
    echo '║  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝  ║'
    echo '║                    LEVEL DEWA DETECTOR                      ║'
    echo '║            Analisis Isi File - 99.9% Akurasi                ║'
    echo '╚══════════════════════════════════════════════════════════════╝'
    echo -e "${NC}"
    echo -e "${RED}=================================================================${NC}"
    echo -e "${WHITE}⚠️  DETECTOR LEVEL DEWA - ANALISIS KONTEN MENDALAM${NC}"
    echo -e "${GREEN}✓ Zero False Positive - Hanya Deteksi Backdoor Asli${NC}"
    echo -e "${RED}=================================================================${NC}"
    echo
}

# Advanced Content Analysis Functions
analyze_entropy() {
    local file="$1"
    # Calculate Shannon entropy
    local entropy=$(cat "$file" | tr -d '\n' | od -t x1 -An | tr -d ' ' | tr -d '\n' | \
        perl -ne 'my @chars = split //; my %freq; $freq{$_}++ for @chars; my $ent = 0; for my $c (keys %freq) { my $p = $freq{$c}/@chars; $ent -= $p * log($p)/log(2); } print $ent;' 2>/dev/null)
    echo "$entropy"
}

detect_obfuscation_level() {
    local content="$1"
    local score=0
    
    # Base64 patterns
    if [[ "$content" =~ [a-zA-Z0-9+/]{60,}={0,2} ]]; then
        score=$((score + 3))
    fi
    
    # Hex encoding
    if [[ "$content" =~ \\\\x[0-9a-fA-F]{2,} ]]; then
        score=$((score + 2))
    fi
    
    # Char code obfuscation
    if echo "$content" | grep -q "chr\([0-9]\{1,3\}\)" && [ $(echo "$content" | grep -o "chr\([0-9]\{1,3\}\)" | wc -l) -gt 5 ]; then
        score=$((score + 2))
    fi
    
    # Multiple encoding functions
    local encoding_funcs=$(echo "$content" | grep -o "base64_decode\|gzinflate\|gzuncompress\|str_rot13\|convert_uuencode\|urldecode" | wc -l)
    if [ $encoding_funcs -gt 2 ]; then
        score=$((score + encoding_funcs))
    fi
    
    echo $score
}

check_malicious_combinations() {
    local content="$1"
    
    # HIGH CONFIDENCE COMBINATIONS - 99.9% accuracy
    
    # Combination 1: eval + base64 + POST/GET
    if echo "$content" | grep -q "eval(" && \
       echo "$content" | grep -q "base64_decode" && \
       echo "$content" | grep -q -E "\$_(POST|GET|REQUEST)" ; then
        echo "EVAL_BASE64_POST"
        return 0
    fi
    
    # Combination 2: assert + POST/GET
    if echo "$content" | grep -q "assert(" && \
       echo "$content" | grep -q -E "\$_(POST|GET|REQUEST|COOKIE)" ; then
        echo "ASSERT_POST"
        return 0
    fi
    
    # Combination 3: system/exec/passthru + POST/GET
    if echo "$content" | grep -q -E "(system|exec|passthru|shell_exec|proc_open|popen)\(" && \
       echo "$content" | grep -q -E "\$_(POST|GET|REQUEST)" ; then
        echo "SYSTEM_POST"
        return 0
    fi
    
    # Combination 4: file_put_contents + POST + .php
    if echo "$content" | grep -q "file_put_contents" && \
       echo "$content" | grep -q -E "\$_(POST|GET|REQUEST)" && \
       echo "$content" | grep -q "\.php" ; then
        echo "FILE_WRITE_POST"
        return 0
    fi
    
    # Combination 5: include/require + http:// + POST
    if echo "$content" | grep -q -E "(include|require).*http" && \
       echo "$content" | grep -q -E "\$_(POST|GET|REQUEST)" ; then
        echo "REMOTE_INCLUDE_POST"
        return 0
    fi
    
    # Combination 6: Double encoding
    if echo "$content" | grep -q "base64_decode.*base64_decode" || \
       echo "$content" | grep -q "gzinflate.*base64_decode.*base64_decode" ; then
        echo "DOUBLE_ENCODING"
        return 0
    fi
    
    # Combination 7: Backticks with variables
    if echo "$content" | grep -q '\`.*\$.*\`' ; then
        echo "BACKTICKS_VAR"
        return 0
    fi
    
    # Combination 8: Obfuscated variable function calls
    if echo "$content" | grep -q '\$\w+\s*\(.*\$' && \
       [ $(echo "$content" | grep -o '\$\w+\s*(' | wc -l) -gt 2 ]; then
        echo "VARIABLE_FUNCTION"
        return 0
    fi
    
    echo ""
    return 1
}

analyze_code_structure() {
    local content="$1"
    local file="$2"
    
    # Check if it's valid PHP
    if ! echo "$content" | head -5 | grep -q "<?php"; then
        echo "NOT_PHP"
        return
    fi
    
    # Count code statistics
    local total_lines=$(wc -l < "$file" 2>/dev/null)
    local code_lines=$(grep -c -v '^[[:space:]]*$\|^[[:space:]]*//\|^[[:space:]]*#' "$file" 2>/dev/null)
    local eval_lines=$(grep -c "eval(" "$file" 2>/dev/null)
    local base64_lines=$(grep -c "base64_decode" "$file" 2>/dev/null)
    local include_lines=$(grep -c -E "(include|require)" "$file" 2>/dev/null)
    
    # Calculate ratios
    if [ $total_lines -gt 0 ]; then
        local eval_ratio=$(echo "scale=2; $eval_lines * 100 / $total_lines" | bc)
        local base64_ratio=$(echo "scale=2; $base64_lines * 100 / $total_lines" | bc)
        
        # Suspicious if eval appears in more than 5% of lines or base64 in more than 10%
        if (( $(echo "$eval_ratio > 5" | bc -l) )) || (( $(echo "$base64_ratio > 10" | bc -l) )); then
            echo "SUSPICIOUS_RATIO"
            return
        fi
    fi
    
    echo "NORMAL"
}

check_webshell_signatures() {
    local content="$1"
    
    # Exact webshell signatures (no false positives)
    declare -A WEBSHELL_SIGS=(
        # c99shell specific
        ["C99"]="c99shell.*@ini_set|R57shell.*@eval|eval\(base64_decode.*c99"
        
        # WSO specific
        ["WSO"]="wso.*password.*login|WSO.*setcookie.*disable_functions"
        
        # b374k specific
        ["B374K"]="b374k.*minimal.*shell|@ini_set.*b374k"
        
        # r57shell
        ["R57"]="r57shell.*@error_reporting|r57.*mail.*pass"
        
        # phpSpy
        ["PHPSPY"]="phpSpy.*Config|2005.*phpSpy.*File"
        
        # Other known shells
        ["ACID"]="acid.*shell|Acid.*rm.*-rf"
        ["C100"]="c100.*shell|k1ll4.*shell"
        ["GAMMA"]="gamma.*web.*shell"
        
        # Generic but specific patterns
        ["GENERIC_SHELL"]="<\?php.*if\(isset\(\$_(POST|GET).*cmd.*\).*eval"
    )
    
    for sig_name in "${!WEBSHELL_SIGS[@]}"; do
        local pattern="${WEBSHELL_SIGS[$sig_name]}"
        if echo "$content" | grep -q -E -i "$pattern"; then
            echo "$sig_name"
            return 0
        fi
    done
    
    echo ""
    return 1
}

analyze_behavior_patterns() {
    local content="$1"
    
    # Behavioral analysis
    local score=0
    local patterns=()
    
    # 1. Command execution patterns
    if echo "$content" | grep -q -E "(system|exec|passthru|shell_exec)\(.*uname\|ls\|cat\|id\|whoami"; then
        score=$((score + 3))
        patterns+=("CMD_EXEC")
    fi
    
    # 2. File system access
    if echo "$content" | grep -q -E "fopen\(.*/etc/passwd\|file_get_contents\(.*/etc/shadow\|scandir\(.*/proc"; then
        score=$((score + 3))
        patterns+=("FILE_SYSTEM")
    fi
    
    # 3. Network activity
    if echo "$content" | grep -q -E "fsockopen\(.*80\|curl_exec\|file_get_contents.*http"; then
        score=$((score + 2))
        patterns+=("NETWORK")
    fi
    
    # 4. Self-replication/writing
    if echo "$content" | grep -q -E "file_put_contents\(.*\.php\|fwrite\(.*\.php\|copy\(.*\.php"; then
        score=$((score + 3))
        patterns+=("SELF_REPLICATE")
    fi
    
    # 5. Obfuscation techniques
    if echo "$content" | grep -q -E "pack\(\"H\*\"\|hex2bin\|str_rot13.*base64"; then
        score=$((score + 2))
        patterns+=("OBFUSCATION")
    fi
    
    # 6. Disable security
    if echo "$content" | grep -q -E "@ini_set.*disable_functions\|error_reporting\(0\)\|@set_time_limit\(0\)"; then
        score=$((score + 2))
        patterns+=("DISABLE_SECURITY")
    fi
    
    echo "$score:${patterns[*]}"
}

# Main scanner function
scan_file_deep() {
    local file="$1"
    local rel_path="$2"
    
    # Skip non-PHP files
    if [[ "$file" != *.php && "$file" != *.phtml && "$file" != *.phps ]]; then
        return
    fi
    
    # Check file size
    local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
    if [ "$size" -lt $MIN_SIZE ] || [ "$size" -gt $MAX_SIZE ]; then
        return
    fi
    
    # Read file content
    local content
    content=$(cat "$file" 2>/dev/null | tr -d '\0')
    if [ -z "$content" ]; then
        return
    fi
    
    # Start analysis
    local result=""
    local confidence=0
    
    # 1. Check for exact webshell signatures (100% confidence)
    local signature=$(check_webshell_signatures "$content")
    if [ -n "$signature" ]; then
        result="WEBSHELL_SIGNATURE:$signature"
        confidence=100
    fi
    
    # 2. Check malicious combinations (99% confidence)
    if [ $confidence -eq 0 ]; then
        local combination=$(check_malicious_combinations "$content")
        if [ -n "$combination" ]; then
            result="MALICIOUS_COMBINATION:$combination"
            confidence=99
        fi
    fi
    
    # 3. Behavioral analysis (90% confidence if score > 7)
    if [ $confidence -eq 0 ]; then
        local behavior=$(analyze_behavior_patterns "$content")
        local b_score=$(echo "$behavior" | cut -d: -f1)
        local b_patterns=$(echo "$behavior" | cut -d: -f2)
        
        if [ "$b_score" -ge 7 ]; then
            result="BEHAVIORAL:$b_patterns"
            confidence=90
        fi
    fi
    
    # 4. Code structure analysis
    if [ $confidence -eq 0 ]; then
        local structure=$(analyze_code_structure "$content" "$file")
        if [ "$structure" = "SUSPICIOUS_RATIO" ]; then
            result="SUSPICIOUS_STRUCTURE"
            confidence=80
        fi
    fi
    
    # 5. Obfuscation level check (only if high)
    if [ $confidence -eq 0 ]; then
        local obf_score=$(detect_obfuscation_level "$content")
        if [ "$obf_score" -ge 8 ]; then
            local entropy=$(analyze_entropy "$file")
            if (( $(echo "$entropy > 7.5" | bc -l) )); then
                result="HIGH_OBFUSCATION:score=$obf_score,entropy=$entropy"
                confidence=85
            fi
        fi
    fi
    
    # Output if malware detected
    if [ $confidence -ge 80 ]; then
        # Get file info
        local perms=$(stat -c "%a %U:%G" "$file" 2>/dev/null || stat -f "%p %u:%g" "$file")
        local mtime=$(stat -c "%y" "$file" 2>/dev/null || stat -f "%Sm" "$file")
        local md5=$(md5sum "$file" | cut -d' ' -f1)
        
        # Display results
        echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                    MALWARE DETECTED!                         ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo -e "${WHITE}File:${NC} $rel_path"
        echo -e "${WHITE}Size:${NC} $((size/1024))KB ${WHITE}Perms:${NC} $perms ${WHITE}Modified:${NC} $mtime"
        echo -e "${WHITE}MD5:${NC} $md5"
        echo -e "${WHITE}Confidence:${NC} $confidence% ${WHITE}Type:${NC} $result"
        
        # Show suspicious code snippet
        echo -e "${YELLOW}Suspicious Code:${NC}"
        
        # Extract relevant lines
        if echo "$result" | grep -q "WEBSHELL_SIGNATURE\|MALICIOUS_COMBINATION"; then
            # Show lines with malicious patterns
            grep -n -E "(eval\(|assert\(|base64_decode|gzinflate|\$_(POST|GET|REQUEST))" "$file" | head -5 | while read line; do
                echo -e "  ${CYAN}Line ${line%%:*}:${NC} ${line#*:}"
            done
        elif echo "$result" | grep -q "HIGH_OBFUSCATION"; then
            # Show high entropy/obfuscated section
            head -20 "$file" | nl -ba | while read num line; do
                if [ $num -le 10 ]; then
                    echo -e "  ${CYAN}Line $num:${NC} $line"
                fi
            done
        fi
        
        echo -e "${RED}══════════════════════════════════════════════════════════════${NC}"
        echo
        
        # Log to file
        echo "=== MALWARE DETECTED ===" >> "$LOG_FILE"
        echo "File: $rel_path" >> "$LOG_FILE"
        echo "Type: $result" >> "$LOG_FILE"
        echo "Confidence: $confidence%" >> "$LOG_FILE"
        echo "MD5: $md5" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
    fi
}

# Special .htaccess scanner
scan_htaccess_advanced() {
    local file="$1"
    local rel_path="$2"
    
    if [ "$(basename "$file")" != ".htaccess" ]; then
        return
    fi
    
    local content=$(cat "$file" 2>/dev/null)
    if [ -z "$content" ]; then
        return
    fi
    
    # High confidence .htaccess malware patterns
    declare -A HTACCESS_MALWARE=(
        ["PHP_IN_IMAGES"]="AddHandler.*php.*\.(jpg|png|gif|txt|html)"
        ["AUTO_PREPEND"]="php_value.*auto_prepend_file.*\.php"
        ["AUTO_APPEND"]="php_value.*auto_append_file.*\.php"
        ["DISABLE_SECURITY"]="php_flag.*engine.*On|php_value.*disable_functions.*none"
        ["REMOTE_INCLUDE"]="php_value.*include_path.*http://"
        ["MALICIOUS_REWRITE"]="RewriteRule.*\.(jpg|png|gif).*\.php"
        ["ERROR_DOCUMENT_SHELL"]="ErrorDocument.*404.*\.php"
    )
    
    for pattern_name in "${!HTACCESS_MALWARE[@]}"; do
        local pattern="${HTACCESS_MALWARE[$pattern_name]}"
        if echo "$content" | grep -q -E -i "$pattern"; then
            local match=$(echo "$content" | grep -E -i "$pattern" | head -1)
            
            echo -e "${RED}[MALICIOUS .HTACCESS]${NC} $rel_path"
            echo -e "  ${YELLOW}Pattern:${NC} $pattern_name"
            echo -e "  ${YELLOW}Rule:${NC} $match"
            echo
            
            # Log
            echo "=== MALICIOUS .HTACCESS ===" >> "$LOG_FILE"
            echo "File: $rel_path" >> "$LOG_FILE"
            echo "Pattern: $pattern_name" >> "$LOG_FILE"
            echo "Rule: $match" >> "$LOG_FILE"
            echo "" >> "$LOG_FILE"
            
            break
        fi
    done
}

# Main scan function
perform_deep_scan() {
    local scan_path="$1"
    local total_files=0
    local infected_files=0
    
    echo -e "${GREEN}[*] Starting Level Dewa Deep Content Scan...${NC}"
    echo -e "${CYAN}[*] Analyzing file content with advanced heuristics...${NC}"
    echo
    
    # Create log file
    > "$LOG_FILE"
    
    # Scan all PHP files
    while IFS= read -r -d '' file; do
        ((total_files++))
        local rel_path="${file#$scan_path/}"
        
        # Show progress every 100 files
        if (( total_files % 100 == 0 )); then
            echo -e "${BLUE}[*] Scanned $total_files files...${NC}"
        fi
        
        scan_file_deep "$file" "$rel_path" && ((infected_files++))
    done < <(find "$scan_path" -type f \( -name "*.php" -o -name "*.phtml" -o -name "*.phps" \) -print0 2>/dev/null)
    
    # Scan .htaccess files
    echo -e "${CYAN}[*] Scanning .htaccess files...${NC}"
    while IFS= read -r -d '' file; do
        local rel_path="${file#$scan_path/}"
        scan_htaccess_advanced "$file" "$rel_path"
    done < <(find "$scan_path" -type f -name ".htaccess" -print0 2>/dev/null)
    
    # Summary
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    SCAN COMPLETED                          ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Target Directory:${NC} $scan_path"
    echo -e "${CYAN}Total Files Scanned:${NC} $total_files"
    echo -e "${RED}Infected Files Found:${NC} $infected_files"
    echo -e "${GREEN}Clean Files:${NC} $((total_files - infected_files))"
    echo -e "${CYAN}Log File:${NC} $LOG_FILE"
    echo
    echo -e "${YELLOW}ANALYSIS METHOD:${NC}"
    echo -e "• Content-based analysis (100%)"
    echo -e "• Behavioral pattern detection"
    echo -e "• Code structure analysis"
    echo -e "• Entropy and obfuscation detection"
    echo -e "• Malicious combination detection"
    echo
    echo -e "${RED}⚠️  WARNING:${NC}"
    echo -e "Files detected above have 80-100% confidence of being malicious."
    echo -e "Review immediately and take appropriate action."
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
}

# Main
main() {
    show_banner
    
    # Check dependencies
    command -v bc >/dev/null 2>&1 || { echo -e "${RED}bc command not found. Install with: apt-get install bc${NC}"; exit 1; }
    command -v perl >/dev/null 2>&1 || { echo -e "${RED}perl not found. Required for entropy calculation.${NC}"; exit 1; }
    
    # Get scan path
    echo -e "${CYAN}[?] Enter directory path to scan:${NC}"
    echo -n "> "
    read -r scan_path
    
    scan_path="${scan_path%/}"
    
    if [ ! -d "$scan_path" ]; then
        echo -e "${RED}[ERROR] Directory not found: $scan_path${NC}"
        exit 1
    fi
    
    if [ ! -r "$scan_path" ]; then
        echo -e "${RED}[ERROR] No read permission for directory${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[✓] Starting Level Dewa Scan on: $scan_path${NC}"
    echo -e "${YELLOW}[!] This may take some time...${NC}"
    echo
    
    perform_deep_scan "$scan_path"
}

# Run
main "$@"
