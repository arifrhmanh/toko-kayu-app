/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('orders', (table) => {
        table.uuid('id').primary().defaultTo(knex.fn.uuid());
        table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
        table.uuid('alamat_id').references('id').inTable('alamat').onDelete('SET NULL');
        table.enum('status', ['pending', 'expired', 'dibayar', 'dikemas', 'dikirim', 'selesai', 'batal']).notNullable().defaultTo('pending');
        table.integer('total_harga').notNullable().defaultTo(0);
        table.string('midtrans_order_id', 100);
        table.text('midtrans_token');
        table.text('midtrans_redirect_url');
        table.timestamp('created_at').defaultTo(knex.fn.now());
        table.timestamp('updated_at').defaultTo(knex.fn.now());
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('orders');
};