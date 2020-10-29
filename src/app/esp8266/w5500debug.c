  C(getphylink)             //c phylink@  { -- i }
  C(getphypmode)            //c phypmode@  { -- i }
  C(setphypmode)            //c phypmode!  { i -- }
  C(handlePackets) //c handlePackets { -- i.err }
  C(read_byte) //c read_byte { a.adr i.block -- i.byte }
  C(read_word) //c read_word { a.adr i.block -- i.word }
  C(read_buf)     //c read_buf { i.len a.buf a.adr i.block -- }
  C(write_byte)   //c write_byte { i.byte a.adr i.block -- }
  C(write_creg)   //c write_creg(uint16_t { i.byte a.adr i.block -- }
  C(write_sreg)   //c write_sreg(uint16_t { i.byte a.adr i.block -- }
  C(write_word)   //c write_word { i.word a.adr i.block -- }
  C(write_buf)    //c write_buf { i.len a.buf a.adr i.block -- }
  C(setSn_CR)     //c setSn_CR { i.cr -- }
  C(getSn_TX_FSR) //c getSn_TX_FSR { -- i.word }
  C(getSn_RX_RSR) //c getSn_RX_RSR() { -- i.word }
  C(send_data)  //c send_data { i.len a.adr -- }
  C(recv_data)  //c recv_data { i.len a.adr -- }
  C(sw_reset)  //c sw_reset { -- }
  C(getPHYCFGR) //c getPHYCFGR { -- i.byte }
  C(setPHYCFGR)   //c setPHYCFGR { i.byte -- }
  C(resetphy)  //c resetphy { -- }
  C(readFrameSize) //c readFrameSize { -- i }
  C(readFrameData) //c readFrameData { i.len a.buf -- i.len }
  C(readFrame)   //c readFrame { i.len a.buf -- i.word }
  C(sendFrame) //c sendFrame { i.len a.buf -- i.len }
  C(linkoutput) //c linkoutput { a.pbuf a.netif -- i.err }
  C(w5500_netif_init) //c w5500_netif_init { -- i.err }
  C(start_with_dhclient) //c start_with_dhclient { -- i.err }
