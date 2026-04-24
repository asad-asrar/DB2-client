const fs = require('fs');
const jose = require('jose');

// RAKBANK specified algorithms
const ALGORITHMS = {
    JWS_SIGNATURE: 'RS256',
    JWE_KEY_ENCRYPTION: 'RSA-OAEP-256',
    JWE_CONTENT_ENCRYPTION: 'A256CBC-HS512'
};

async function runDecryptionUtility() {
    console.log("=========================================");
    console.log("  RAKBANK Payload Decryption Utility");
    console.log("=========================================\n");

    // 1. Get file paths from command line arguments (or use defaults)
    const args = process.argv.slice(2);
    const payloadPath = args[0] || './encrypted-payload.json';
    const privateKeyPath = args[1] || './client-private-key.pem';
    const publicKeyPath = args[2] || './rakbank-public.cer';
    const outputPath = './decrypted-output.json';

    try {
        // 2. Read the files from the local system
        console.log(`[1/4] Reading files...`);
        if (!fs.existsSync(payloadPath)) throw new Error(`Payload file not found: ${payloadPath}`);
        if (!fs.existsSync(privateKeyPath)) throw new Error(`Private key file not found: ${privateKeyPath}`);
        if (!fs.existsSync(publicKeyPath)) throw new Error(`Public cert file not found: ${publicKeyPath}`);

        const encryptedPayloadJson = JSON.parse(fs.readFileSync(payloadPath, 'utf8'));
        const clientPrivateKeyPem = fs.readFileSync(privateKeyPath, 'utf8');
        const rakbankPublicKeyPem = fs.readFileSync(publicKeyPath, 'utf8');

        // 3. Import Keys
        console.log(`[2/4] Importing cryptographic keys...`);
        const clientPrivateKey = await jose.importPKCS8(clientPrivateKeyPem, ALGORITHMS.JWE_KEY_ENCRYPTION);
        const rakbankPublicKey = await jose.importSPKI(rakbankPublicKeyPem, ALGORITHMS.JWS_SIGNATURE);

        // 4. Decrypt the JWE using your Client Private Key
        console.log(`[3/4] Decrypting JWE payload...`);
        const { plaintext } = await jose.flattenedDecrypt(encryptedPayloadJson, clientPrivateKey);
        const jwsPayloadJson = JSON.parse(new TextDecoder().decode(plaintext));

        // 5. Verify the JWS signature using RAKBANK's Public Certificate
        console.log(`[4/4] Verifying JWS signature...`);
        const { payload } = await jose.flattenedVerify(jwsPayloadJson, rakbankPublicKey);
        const finalJsonString = new TextDecoder().decode(payload);

        // 6. Save the output
        fs.writeFileSync(outputPath, JSON.stringify(JSON.parse(finalJsonString), null, 2));
        
        console.log("\n✅ SUCCESS! Payload decrypted and verified.");
        console.log(`📂 Output saved to: ${outputPath}\n`);

    } catch (error) {
        console.error("\n❌ ERROR FAILED TO DECRYPT/VERIFY:");
        console.error(error.message);
        console.log("\nPlease ensure your keys are in valid PEM format and the payload is a valid JWE JSON.");
    }
}

runDecryptionUtility();
