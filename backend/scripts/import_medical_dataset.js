const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { connectMySQL, disconnectMySQL, query } = require('../src/db');
const bcrypt = require('bcryptjs'); // Assuming they use bcrypt for passwords

async function importDataset() {
  try {
    console.log('Connecting to database...');
    await connectMySQL();
    
    // 1. Create or get "Global Pharmacy" user
    const pharmacyEmail = 'global@pharmacy.com';
    let userRows = await query('SELECT id FROM users WHERE email = ?', [pharmacyEmail]);
    let userId;
    
    if (userRows.length === 0) {
      console.log('Creating Global Pharmacy user...');
      const defaultPassword = 'password123';
      
      // I am generating a fake hash or using bcrypt if available
      let passwordHash = 'dummy_hash_update_me';
      try {
        const bcrypt = require('bcrypt');
        passwordHash = await bcrypt.hash(defaultPassword, 10);
      } catch (e) {
        // Just use a dummy hash if bcrypt is not easily available in script context
      }

      const result = await query(
        `INSERT INTO users (fullName, email, passwordHash, role, status) VALUES (?, ?, ?, ?, ?)`,
        ['Global Pharmacy', pharmacyEmail, passwordHash, 'pharmacy', 'active']
      );
      userId = result.insertId;
    } else {
      userId = userRows[0].id;
    }

    // 2. Create or get medical_shops entry
    let shopRows = await query('SELECT id FROM medical_shops WHERE userId = ?', [userId]);
    let shopId;

    if (shopRows.length === 0) {
      console.log('Creating Global Pharmacy shop profile...');
      const result = await query(
        `INSERT INTO medical_shops (userId, shopName, ownerName, phoneNumber, email, address) VALUES (?, ?, ?, ?, ?, ?)`,
        [userId, 'Global Pharmacy Network', 'System Admin', '1-800-PHARMACY', pharmacyEmail, '123 Main Street, Medical District']
      );
      shopId = result.insertId;
    } else {
      shopId = shopRows[0].id;
    }

    console.log(`Global Pharmacy configured with shopId: ${shopId}`);

    // 3. Read dataset
    const datasetPath = path.join(__dirname, 'medical_dataset.json');
    const rawData = fs.readFileSync(datasetPath, 'utf8');
    const medicines = JSON.parse(rawData);

    // 4. Insert medicines
    console.log(`Importing ${medicines.length} medicines...`);
    let imported = 0;
    
    for (const med of medicines) {
      // Check if medicine already exists for this shop to avoid duplicates
      const exist = await query('SELECT id FROM shop_medicines WHERE shopId = ? AND name = ?', [shopId, med.name]);
      
      if (exist.length === 0) {
        await query(
          `INSERT INTO shop_medicines 
          (shopId, name, category, manufacturer, batchNumber, price, stockQuantity, expiryDate, imageUrl, description, prescriptionRequired)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            shopId,
            med.name,
            med.category,
            med.manufacturer,
            med.batchNumber,
            med.price,
            med.stockQuantity,
            med.expiryDate,
            med.imageUrl,
            med.description,
            med.prescriptionRequired ? 1 : 0
          ]
        );
        imported++;
      }
    }

    console.log(`Successfully imported ${imported} new medicines.`);

  } catch (error) {
    console.error('Error importing dataset:', error);
  } finally {
    await disconnectMySQL();
    console.log('Done.');
  }
}

importDataset();
