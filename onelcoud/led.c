//https://github.com/hzyitc/armbian-onecloud/issues/52

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/select.h>
#include <pthread.h>
#include <unistd.h>
#include <sched.h>
#include <string.h>

#define PLPM_BASE 0xc8100014

#define __IO volatile

void          *var_addr_satr=0;
unsigned int   var_addr_size=0;
unsigned int  *gpioaddr;
void          *gpio_base= 0;

int gpio_init(void) {
  int fd;
  unsigned int addr_start,addr_offset;
  unsigned int PageSize,PageMask;

  fd = open("/dev/mem",O_RDWR);
  if(fd < 0) {
    return -1;
  }
 
  PageSize = sysconf(_SC_PAGESIZE);
  PageMask = ~(PageSize-1);
 
  //printf("take PageSize=%d\n",PageSize);
  addr_start =  PLPM_BASE & PageMask ;
  addr_offset=  PLPM_BASE & ~PageMask;

  var_addr_size =  PageSize*2;
  var_addr_satr = (void*) mmap(0, var_addr_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr_start);

  if(var_addr_satr == MAP_FAILED) {
    return -1;
  }

  gpio_base = var_addr_satr;
  gpio_base += addr_offset;

  //printf("take var addr = 0x%8x\n",(unsigned int)var_addr_satr);
  //printf("make gpio_base = 0x%8x\n",(unsigned int)gpio_base);

  close(fd);
  return 0;
}

int gpio_deinit(void) {
  int fd;

  fd = open("/dev/mem",O_RDWR);
  if(fd < 0) {
    return -1;
  }

  if(munmap(var_addr_satr,var_addr_size) == 0) {
      //printf("remove var addr ok\n");
  } else {
  	//printf("remove var addr erro\n");
  }

  close(fd);
  return 0;
}

void red_on(void) {
  unsigned int temp;
  temp = *(gpioaddr+4)|0x00040000;
  *(gpioaddr+4)=temp;
}
void red_off(void) {
  *(gpioaddr+4) = *(gpioaddr+4)&(~0x00040000);
}
void red_toggle(void) {
  unsigned char c;
  c = (*(gpioaddr+4)&0x00040000)>>18;
  if (c == 0) {
    red_on();
  } else {
    red_off();
  }
}

void green_on(void) {
  *(gpioaddr+4) = *(gpioaddr+4)|0x00080000;
}
void green_off(void) {
  *(gpioaddr+4) = *(gpioaddr+4)&(~0x00080000);
}
void green_toggle(void) {
  unsigned char c;
  c = (*(gpioaddr+4)&0x00080000)>>19;
  if (c == 0) {
    green_on();
  } else {
    green_off();
  }
}

void blue_on(void) {
  *(gpioaddr+4) = *(gpioaddr+4)|0x00100000;
}
void blue_off(void) {
  *(gpioaddr+4) = *(gpioaddr+4)&(~0x00100000);
}
void blue_toggle(void) {
  unsigned char c;
  c = (*(gpioaddr+4)&0x00100000)>>20;
  if (c == 0) {
    blue_on();
  } else {
    blue_off();
  }
}

unsigned char key_scan(void) {
  unsigned char key=0;
  key=((*(gpioaddr+5)&0x00000020)>>5);
  return key;
} 

int main(int argc,char * argv[]) {
  if (argc < 2 || argc > 4) {
    printf("led [red|green|blue] [0|1]\n");
    return 1;
  }

  unsigned int temp;
  if (gpio_init() != 0) {
    printf("gpio_init failed\n");
    return -1;
  }

  gpioaddr = (unsigned int *)gpio_base;
  // Turn off GPIOAO_4,GPIOAO_5 reuse 
  temp = *gpioaddr&(~0x01800066);
  *gpioaddr = temp;
  // Enable GPIOAO_2,GPIOAO_3,GPIOAO_4 output,GPIOAO_5 input
  temp = *(gpioaddr+4)&(~0x0000001c);
  *(gpioaddr+4) = temp;

  temp = *(gpioaddr+4)|0x00000020;
  *(gpioaddr+4) = temp;

  if (argc == 2) {
    if (strcmp((const char*)argv[1],"red")==0)
      red_toggle();

    if (strcmp((const char*)argv[1],"green")==0)
      green_toggle();

    if (strcmp((const char*)argv[1],"blue")==0)
      blue_toggle();
  }

  if (argc == 3) {
    if (strcmp((const char*)argv[1],"red")==0) {
      if (strcmp((const char*)argv[2],"0")==0) {
        red_off();
      } else {
        red_on();
      }
    }

    if (strcmp((const char*)argv[1],"green")==0) {
      if (strcmp((const char*)argv[2],"0")==0) {
        green_off();
      } else {
        green_on();
      }
    }

    if (strcmp((const char*)argv[1],"blue")==0) {
      if (strcmp((const char*)argv[2],"0")==0) {
        blue_off();
      } else {
        blue_on();
      }
    }
  }

  gpio_deinit( );
  return 0;
}
