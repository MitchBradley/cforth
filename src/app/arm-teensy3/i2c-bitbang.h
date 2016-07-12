// void i2c_setup(cell sda, cell scl);
void i2c_setup(uint8_t sda, uint8_t scl);
void i2c_master_start();
void i2c_master_stop();
cell i2c_send(cell byte);
cell i2c_recv(cell nack);
// Start + slave address + reg#
cell i2c_start_write(cell slave, cell reg);
cell i2c_start_read(cell slave, cell stop);
cell i2c_rb(cell stop, cell slave, cell reg);
cell i2c_wb(cell slave, cell reg, cell value);
cell i2c_be_rw(cell stop, cell slave, cell reg);
cell i2c_le_rw(cell stop, cell slave, cell reg);
cell i2c_be_ww(cell slave, cell reg, cell value);
cell i2c_le_ww(cell slave, cell reg, cell value);
