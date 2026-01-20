/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('produk', (table) => {
        table.uuid('id').primary().defaultTo(knex.fn.uuid());
        table.string('nama_produk', 150).notNullable();
        table.integer('harga_jual').notNullable().defaultTo(0);
        table.string('gambar_url', 500);
        table.integer('stok').notNullable().defaultTo(0);
        table.integer('stok_minimum').notNullable().defaultTo(10);
        table.timestamp('created_at').defaultTo(knex.fn.now());
        table.timestamp('updated_at').defaultTo(knex.fn.now());
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('produk');
};
