/*
 * txtmsg.ino  part of MavLink_FrSkySPort
 * 
 * Copyright (C) 2015 Jochen Kielkopf
 * https://github.com/Clooney82/MavLink_FrSkySPort
 * 
 * codeparts from:   
 *    (2015) Scott Simpson
 *    https://github.com/scottflys/mavsky
 * 
 * https://github.com/Clooney82/MavLink_FrSkySPort
 * 
 * This program is free software; you can redistribute it and/or modify 
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY, without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA/*
 *
 */
#ifdef SEND_STATUS_TEXT_MESSAGE


#define TELEM_TEXT_MESSAGE_MAX  128
#define TELEM_NUM_BUFFERS         8

char telem_text_message_data_buffer[TELEM_NUM_BUFFERS][TELEM_TEXT_MESSAGE_MAX];
uint8_t telem_text_message_index = 0;
uint32_t telem_message_expiry = 0L;
uint16_t message_packet_sequence = 0;
uint16_t current_message_number = 0;
uint16_t next_message_number = 1;

void frsky_send_text_message(char *msg) {
  uint8_t c;
  uint16_t dst_index = 0;
  for (uint i = 0; i < strlen(msg); i++) {
    c = msg[i];
    if (c >= 32 && c <= 126) {
      telem_text_message_data_buffer[next_message_number % TELEM_NUM_BUFFERS][dst_index++] = c;
    }
  }
  telem_text_message_data_buffer[next_message_number % TELEM_NUM_BUFFERS][dst_index++] = 0;
  next_message_number++;
}

void telem_load_next_buffer() {
  if (millis() > telem_message_expiry) {
    if ((current_message_number + 1) < next_message_number) {
      telem_message_expiry = millis() + 2000;
      current_message_number++;
    } else {
      telem_text_message_data_buffer[current_message_number % TELEM_NUM_BUFFERS][0] = '\0';
      telem_message_expiry = millis();                                                              // No reason to keep blank up for a set time
    }
  }
  telem_text_message_index = 0;
}

char frsky_get_next_message_byte() {
  if (current_message_number == next_message_number) {
    return '\0';
  } else if (telem_text_message_index >= strlen(telem_text_message_data_buffer[current_message_number % TELEM_NUM_BUFFERS])) {
    return '\0';
  } else {
    return telem_text_message_data_buffer[current_message_number % TELEM_NUM_BUFFERS][telem_text_message_index++] & 0x7f;
  }
}

uint16_t telem_text_get_word() {                                                      // LSB is lost so use upper 15 bits
  uint16_t data_word;
  char ch, cl;
  ch = frsky_get_next_message_byte();
  data_word = ch << 8;
  cl = frsky_get_next_message_byte();
  data_word |= cl << 1;
  data_word |= (message_packet_sequence++ & 1) << 15;                                // MSB will change on each telemetry packet so rx knows to update message
  if (ch == '\0' || cl == '\0') {
    telem_load_next_buffer();
  }
  return data_word;
}


#endif
