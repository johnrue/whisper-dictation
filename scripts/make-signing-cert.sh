#!/bin/bash
# Creates a stable, self-signed code-signing identity in the login keychain.
#
# Why this exists: macOS TCC (Accessibility, Microphone, etc.) binds each grant
# to the app's code-signing identity. Ad-hoc signing (`codesign --sign -`)
# produces a new identity on every rebuild, so every rebuild silently loses the
# Accessibility grant — the app keeps copying to the clipboard instead of
# pasting. Signing every build with this one stable identity keeps the grant.
#
# Run once. Safe to re-run: it no-ops if the identity already exists.
set -euo pipefail

CERT_CN="Whisper Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning | grep -q "$CERT_CN"; then
    echo "Signing identity '$CERT_CN' already exists — nothing to do."
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Use the system LibreSSL, not a Homebrew/Anaconda OpenSSL 3 that may be ahead
# on PATH: OpenSSL 3's default PKCS12 ciphers can't be imported by macOS's
# Security framework ("MAC verification failed").
OPENSSL=/usr/bin/openssl

cat > "$TMP/cert.conf" <<EOF
[ req ]
distinguished_name = dn
x509_extensions    = v3
prompt             = no
[ dn ]
CN = $CERT_CN
[ v3 ]
basicConstraints     = critical,CA:false
keyUsage             = critical,digitalSignature
extendedKeyUsage     = critical,codeSigning
EOF

"$OPENSSL" req -x509 -newkey rsa:2048 -nodes \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
    -days 3650 -config "$TMP/cert.conf" >/dev/null 2>&1

"$OPENSSL" pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -out "$TMP/identity.p12" -passout pass:whisper -name "$CERT_CN" >/dev/null 2>&1

# -T /usr/bin/codesign lets codesign use the private key.
security import "$TMP/identity.p12" -k "$KEYCHAIN" -P whisper -T /usr/bin/codesign

# Let codesign use the key without prompting on every build. Needs the login
# keychain password; if it can't be set non-interactively you'll just get a
# one-time "codesign wants to use key" prompt on the next build — click
# "Always Allow" and it's set from then on.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s \
    -k "$(security -q find-generic-password -ga login 2>/dev/null || true)" \
    "$KEYCHAIN" >/dev/null 2>&1 || true

echo "Created signing identity '$CERT_CN'."
