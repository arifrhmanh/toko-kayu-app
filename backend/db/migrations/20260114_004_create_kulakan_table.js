/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('kulakan', (table) => {
        table.uuid('id').primary().defaultTo(knex.fn.uuid());
        table.uuid('produk_id').notNullable().references('id').inTable('produk').onDelete('CASCADE');
        table.integer('jumlah_karung').notNullable();
        table.integer('harga_per_karung').notNullable();
        table.integer('total_harga').notNullable();
        table.timestamp('tanggal').defaultTo(knex.fn.now());
        table.timestamp('created_at').defaultTo(knex.fn.now());
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('kulakan');
};
