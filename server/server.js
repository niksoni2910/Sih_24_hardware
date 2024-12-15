const express = require("express");
const bodyParser = require("body-parser");
const NodeRSA = require("node-rsa");
const jsonfile = require("jsonfile");
const crypto = require("crypto");

const app = express();
const PORT = 3000;
const DB_FILE = "database.json";

app.use(bodyParser.json({ limit: "10mb" })); // Increase payload size if necessary
//load private key
const privateKey = loadPrivateKey();
app.post("/api/send-data", async (req, res) => {
  const {
    devicePublicKey,
    encryptedData,
    encryptedKey,
    deviceInfo,
    deviceInfoSign,
  } = req.body;
  const log = {
    received: {
      devicePublicKey,
      encryptedData: encryptedData.substring(0, 100) + "...",
      encryptedKey: encryptedKey.substring(0, 100) + "...",
      deviceInfo,
      deviceInfoSign,
    },
  };

  try {
    // 1. Store the device public key
    const db = await readDatabase();

    if (db && !db.devices) {
      db.devices = {};
      db.devices[devicePublicKey] = { createdOn: new Date() };
    } else if (db && !db.devices[devicePublicKey]) {
      db.devices[devicePublicKey] = { createdOn: new Date() };
    } else if (db && db.devices && db.devices[devicePublicKey]) {
      //do notthing
    }

    // Write to file
    await writeDatabase(db);
    // 2. Decrypt the AES key using server's private key
    const decryptedAesKey = rsaDecrypt(encryptedKey, privateKey);
    const aesKeyBuffer = Buffer.from(decryptedAesKey, "base64");

    // 3. Decrypt the data using the decrypted AES key
    const decryptedData = aesDecrypt(encryptedData, aesKeyBuffer);
    const parts = decryptedData.split("~");

    if (parts.length != 2) {
      log.decrypted_data_error =
        "decrypted data format is not matching deviceinfo~imageBase64";

      return res
        .status(400)
        .send({ message: "Error during data decryption", log });
    }
    const deviceInfoFromData = parts[0];
    const base64Image = parts[1];

    // 4. Decrypt the deviceInfoSign with server's private key to get original deviceinfo hash and verify
    const decryptedDeviceInfoSign = rsaDecrypt(deviceInfoSign, privateKey);

    // const verifyDeviceSign =    compare(decryptedDeviceInfoSign, deviceInfoFromData)
    const calculatedDeviceInfoHash = crypto
      .createHash("sha256")
      .update(deviceInfoFromData)
      .digest("base64");

    log.decrypted = {
      decryptedAesKey: decryptedAesKey.substring(0, 100) + "...",
      decryptedData: decryptedData.substring(0, 100) + "...",
      deviceInfoFromData,
      decryptedDeviceInfoSign:
        decryptedDeviceInfoSign.substring(0, 100) + "...",
      calculatedDeviceInfoHash:
        calculatedDeviceInfoHash.substring(0, 100) + "...",
      base64Image: base64Image.substring(0, 100) + "...",
    };

    let authenticated = calculatedDeviceInfoHash === decryptedDeviceInfoSign;

    if (!authenticated) {
      log.authentication_message = "Device authentication failed";
      res.status(403).send({ message: "Device Authentication failed", log });
    } else {
      log.authentication_message = "Device authenticated successfully!";

      res
        .status(200)
        .send({ message: "Device authenticated successfully!", log });
    }
    db.devices[devicePublicKey]["history"]
      ? db.devices[devicePublicKey]["history"].push({
          log,
          authenticatedOn: new Date(),
        })
      : (db.devices[devicePublicKey]["history"] = [
          { log, authenticatedOn: new Date() },
        ]);
    await writeDatabase(db);
  } catch (error) {
    log.error = String(error);
    console.error("DEBUG: Server Error", error);
    res.status(500).send({ message: "Internal server error", log });
  }
});

async function readDatabase() {
  try {
    return await jsonfile.readFile(DB_FILE);
  } catch (err) {
    console.log("Database Read Failed: ${err}");
    return {};
  }
}
async function writeDatabase(data) {
  try {
    await jsonfile.writeFile(DB_FILE, data, { spaces: 2 });
  } catch (e) {
    console.error("Database Write Failed :${e}");
  }
}

function loadPrivateKey() {
  try {
    // Load the private key (PEM format from file, env or config )
    const fs = require("node:fs");
    const privateKeyPem = fs.readFileSync("private.pem").toString(); // This would typically come from a file or secure storage
    // Create a NodeRSA object from the private key

    return new NodeRSA(privateKeyPem);
  } catch (err) {
    console.error("DEBUG:  Error Loading Private Key : ${err}");
    return null;
  }
}
function rsaDecrypt(encryptedKeyBase64, key) {
  try {
    const encryptedKeyBuffer = Buffer.from(encryptedKeyBase64, "base64");
    const decrypted = key.decrypt(encryptedKeyBuffer);
    return decrypted.toString("base64");
  } catch (e) {
    console.log("Debug : Error Decrypting key" + String(e));
    return null;
  }
}

function aesDecrypt(encryptedDataBase64, keyBuffer) {
  try {
    const decipher = crypto.createDecipheriv(
      "aes-256-cbc",
      keyBuffer,
      Buffer.alloc(16),
    ); //the iv was created using IV.fromlength, hence 16, so setting that here too

    let decrypted = decipher.update(encryptedDataBase64, "base64", "utf8");

    decrypted += decipher.final("utf8");
    return decrypted;
  } catch (e) {
    console.log("Debug: Error while aes decryption " + String(e));

    return null;
  }
}

app.listen(PORT, () => {
  console.log(`DEBUG: Server running on port ${PORT}`);
});
