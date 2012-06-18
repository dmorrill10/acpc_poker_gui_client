/*
Copyright (C) 2011 by the Computer Poker Research Group, University of Alberta
*/

#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/wait.h>
#include "net.h"


#define ARG_SERVERNAME 1
#define ARG_SERVERPORT 2
#define ARG_BOT_COMMAND 3
#define ARG_NUM_ARGS 4


static void printUsage( FILE *file )
{
  fprintf( file, "usage: bm_widget bm_hostname bm_port bot_command\n" );
  fprintf( file, "  bot_command: agent executable, passed \"hostname port\"\n");
}


/* 0 on success, -1 on failure */
int login( char *user, char *passwd, FILE *conn )
{
  if( fprintf( conn, "%s %s\n", user, passwd ) < 0 ) {

    return -1;
  }
  fflush( conn );

  return 0;
}


int main( int argc, char **argv )
{
  int sock, i;
  pid_t childPID;
  uint16_t port;
  ReadBuf *fromUser, *fromServer;
  fd_set readfds;
  char line[ READBUF_LEN ];

  if( argc < ARG_NUM_ARGS ) {

    printUsage( stderr );
    exit( EXIT_FAILURE );
  }


  /* connect to the server */
  if( sscanf( argv[ ARG_SERVERPORT ], "%"SCNu16, &port ) < 1 ) {

    fprintf( stderr, "ERROR: invalid port %s\n", argv[ ARG_SERVERPORT ] );
    exit( EXIT_FAILURE );
  }
  sock = connectTo( argv[ ARG_SERVERNAME ], port );
  if( sock < 0 ) {

    exit( EXIT_FAILURE );
  }

  /* set up read buffers */
  fromUser = createReadBuf( 0 );
  fromServer = createReadBuf( sock );

  printf( "Log in with 'user password'\n" );
  fflush( stdout );

  /* main loop */
  while( 1 ) {

    /* clean up any children */
    while( waitpid( -1, NULL, WNOHANG ) > 0 );

    /* wait for input */
    FD_ZERO( &readfds );
    FD_SET( 0, &readfds );
    FD_SET( sock, &readfds );
    i = select( sock + 1, &readfds, NULL, NULL, NULL );
    if( i < 0 ) {

      fprintf( stderr, "ERROR: select failed\n" );
      exit( EXIT_FAILURE );
    }
    if( i == 0 ) {
      /* nothing ready - shouldn't happen without timeout */

      continue;
    }

    /* handle user input by passing it directly to server */
    if( FD_ISSET( 0, &readfds ) ) {

      /* get the input */
      while( ( i = getLine( fromUser, READBUF_LEN, line, 0 ) ) >= 0 ) {

	if( i == 0 ) {
	  /* Done! */

	  exit( EXIT_SUCCESS );
	}

	/* write to server */
	if( write( sock, line, i ) < 0 ) {

	  fprintf( stderr, "ERROR: failed while sending to server\n" );
	  exit( EXIT_FAILURE );
	}
      }
    }

    /* handle server messages */
    if( FD_ISSET( sock, &readfds ) ) {

      /* get the input */
      while( ( i = getLine( fromServer, READBUF_LEN, line, 0 ) ) >= 0 ) {

	if( i == 0 ) {

	  fprintf( stderr, "ERROR: server closed connection?\n" );
	  exit( EXIT_FAILURE );
	}

	/* check for server commands */
	if( strncasecmp( line, "run ", 4 ) == 0 ) {

	  /* split the rest of the line into name ' ' port */
	  for( i = 4; line[ i ]; ++i ) {

	    if( line[ i ] == ' ' ) {
	      /* found the separator */

	      line[ i ] = 0;
	      break;
	    }
	  }

	  printf( "starting match %s:%s", &line[ 4 ], &line[ i + 1 ] );

	  /* run `command machine port` */
	  childPID = fork();
	  if( childPID < 0 ) {

	    fprintf( stderr, "ERROR: fork() failed\n" );
	    exit( EXIT_FAILURE );
	  }
	  if( childPID == 0 ) {
	    /* child runs the command */

	    execl( argv[ ARG_BOT_COMMAND ],
		   argv[ ARG_BOT_COMMAND ],
		   &line[ 4 ],
		   &line[ i + 1 ],
		   NULL );
	    fprintf( stderr,
		     "ERROR: could not run %s\n",
		     argv[ ARG_BOT_COMMAND ] );
	    exit( EXIT_FAILURE );
	  }
	} else {
	  /* just a message, print it out */

	  if( fwrite( line, 1, i, stdout ) < 0 ) {

	    fprintf( stderr, "ERROR: failed while printing server message\n" );
	    exit( EXIT_FAILURE );
	  }
	}
      }
    }
  }

  return EXIT_SUCCESS;
}
