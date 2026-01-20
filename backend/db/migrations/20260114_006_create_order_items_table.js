/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('order_items', (table) => {
        table.uuid('id').primary().defaultTo(knex.fn.uuid());
        table.uuid('order_id').notNullable().references('id').inTable('orders').onDelete('CASCADE');
        table.uuid('produk_id').notNullable().references('id').inTable('produk').onDelete('CASCADE');
        table.integer('jumlah').notNullable();
        table.integer('harga_satuan').notNullable();
        table.integer('subtotal').notNullable();
        table.timestamp('created_at').defaultTo(knex.fn.now());
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('order_items');
};
