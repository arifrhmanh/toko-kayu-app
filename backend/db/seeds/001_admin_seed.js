const bcrypt = require('bcryptjs');

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.seed = async function (knex) {
    // Check if admin already exists
    const existingAdmin = await knex('users').where('username', process.env.ADMIN_USERNAME || 'admin').first();

    if (existingAdmin) {
        console.log('Admin user already exists, skipping seed...');
        return;
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'admin123', salt);

    // Insert admin user
    await knex('users').insert({
        username: process.env.ADMIN_USERNAME || 'admin',
        password: hashedPassword,
        role: 'admin',
        nama_lengkap: process.env.ADMIN_NAMA || 'Administrator',
        no_hp: '081234567890'
    });

    console.log('Admin user created successfully!');
};
