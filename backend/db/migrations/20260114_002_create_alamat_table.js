/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('alamat', (table) => {
        table.uuid('id').primary().defaultTo(knex.fn.uuid());
        table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
        table.string('provinsi', 100).notNullable();
        table.string('provinsi_id', 20);
        table.string('kota', 100).notNullable();
        table.string('kota_id', 20);
        table.string('kecamatan', 100).notNullable();
        table.string('kecamatan_id', 20);
        table.string('kelurahan', 100).notNullable();
        table.string('kelurahan_id', 20);
        table.text('detail_alamat');
        table.boolean('is_default').defaultTo(false);
        table.timestamp('created_at').defaultTo(knex.fn.now());
        table.timestamp('updated_at').defaultTo(knex.fn.now());
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('alamat');
};
