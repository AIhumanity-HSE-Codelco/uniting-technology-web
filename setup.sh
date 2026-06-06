#!/bin/bash
# UNITING TECHNOLOGY BV — Auto Setup DEBBIE-002
echo "=== UT SERVER SETUP STARTING ==="

# 1. Update system
apt-get update -qq 2>/dev/null

# 2. Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 2>/dev/null
apt-get install -y nodejs 2>/dev/null
echo "Node: $(node --version)"

# 3. Install PM2 + n8n
npm install -g pm2 n8n 2>/dev/null
echo "PM2: $(pm2 --version)"

# 4. Install PHP for contact forms
apt-get install -y php8.3-fpm php8.3-curl 2>/dev/null

# 5. Install MariaDB
apt-get install -y mariadb-server 2>/dev/null
systemctl start mariadb
systemctl enable mariadb

# 6. Setup DB for leads
mysql -e "CREATE DATABASE IF NOT EXISTS ut_leads; CREATE TABLE IF NOT EXISTS ut_leads.contacts (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255), email VARCHAR(255), organization VARCHAR(255), industry VARCHAR(100), service VARCHAR(100), message TEXT, lang VARCHAR(5), timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, source VARCHAR(255)); GRANT ALL ON ut_leads.* TO 'utadmin'@'localhost' IDENTIFIED BY 'UTdata2025'; FLUSH PRIVILEGES;" 2>/dev/null
echo "Database: ut_leads created"

# 7. Configure Nginx with PHP
cat > /etc/nginx/sites-available/uniting-tech << 'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name uniting-tech.com www.uniting-tech.com _;
    root /var/www/html;
    index index.html index.php;
    gzip on;
    gzip_types text/html text/css application/javascript image/svg+xml application/json;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    location / { try_files $uri $uri/ =404; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }
    location /api/track {
        proxy_pass http://127.0.0.1:3001/track;
        proxy_set_header X-Forwarded-For $remote_addr;
        add_header Access-Control-Allow-Origin *;
    }
    location /webhook/ {
        proxy_pass http://127.0.0.1:5678/webhook/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/uniting-tech /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
systemctl start php8.3-fpm
echo "Nginx: configured"

# 8. Create tracker
mkdir -p /var/www/html
cat > /opt/ut-tracker.js << 'TRACKER'
const http=require('http');const fs=require('fs');
const DB='/var/www/visits.json';
http.createServer((req,res)=>{
res.setHeader('Access-Control-Allow-Origin','*');
if(req.method==='OPTIONS'){res.writeHead(204);res.end();return;}
if(req.method==='POST'&&req.url==='/track'){
let b='';req.on('data',c=>b+=c);req.on('end',()=>{
try{const d=JSON.parse(b);d.t=new Date().toISOString();d.ip=req.headers['x-forwarded-for']||req.socket.remoteAddress;
let v=[];try{v=JSON.parse(fs.readFileSync(DB,'utf8'))}catch(e){}
v.push(d);if(v.length>10000)v=v.slice(-10000);
fs.writeFileSync(DB,JSON.stringify(v));
res.writeHead(200);res.end('{"ok":true}');}catch(e){res.writeHead(400);res.end('{}');}});}
else if(req.url==='/stats'){
try{const v=JSON.parse(fs.readFileSync(DB,'utf8'));res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify({total:v.length,last:v.slice(-10)}));}
catch(e){res.writeHead(200);res.end('{"total":0}');}}
else{res.writeHead(404);res.end();}
}).listen(3001,'127.0.0.1',()=>console.log('Tracker :3001'));
TRACKER

pm2 start /opt/ut-tracker.js --name ut-tracker 2>/dev/null || pm2 restart ut-tracker
pm2 save

# 9. Start n8n
pm2 start n8n --name ut-n8n -- start 2>/dev/null || pm2 restart ut-n8n
pm2 save
pm2 startup 2>/dev/null | tail -1 | bash 2>/dev/null

# 10. Deploy site from GitHub
REPO="https://raw.githubusercontent.com/AIhumanity-HSE-Codelco/uniting-technology-web/main"
for f in index.html contact.php coming-soon.html privacy.html cookies.html cookies.js og-image.svg .htaccess; do
    curl -sL "${REPO}/${f}" -o "/var/www/html/${f}"
    echo "  Deployed: $f ($(wc -c < /var/www/html/${f}) bytes)"
done
chown -R www-data:www-data /var/www/html

echo ""
echo "=== SETUP COMPLETE ==="
pm2 list
echo "Site: http://164.92.221.55"
echo "n8n: http://164.92.221.55:5678"
echo "Tracker: http://164.92.221.55/api/track"
