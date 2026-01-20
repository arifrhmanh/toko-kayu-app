/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('keuangan', (table) => {
        table.uuid('id').primary().defaultTo(knex.fn.uuid());
        table.enum('jenis', ['pemasukan', 'pengeluaran']).notNullable();
        table.integer('jumlah').notNullable();
        table.string('keterangan', 255).notNullable();
        table.uuid('reference_id'); // for linking to orders or kulakan
        table.string('reference_type', 50); // 'order', 'kulakan', 'manual'
        table.timestamp('tanggal').defaultTo(knex.fn.now());
        table.timestamp('created_at').defaultTo(knex.fn.now());
        table.timestamp('updated_at').defaultTo(knex.fn.now());
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
    return knex.schema.dropTableIfExists('keuangan');
};
