/*
Copyright (C) 2011 by the Computer Poker Research Group, University of Alberta
*/

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <getopt.h>
#include "game.h"


int main( int argc, char **argv )
{
  int sock, len, r;
  int32_t min, max;
  uint16_t port;
  Game *game;
  MatchState state;
  Action action;
  struct sockaddr_in addr;
  struct hostent *hostent;
  FILE *file, *toServer, *fromServer;
  char line[ MAX_LINE_LEN ];

  if( argc < 4 ) {

    fprintf( stderr, "usage: player game server port\n" );
    exit( EXIT_FAILURE );
  }

  file = fopen( argv[ 1 ], "r" );
  if( file == NULL ) {

    fprintf( stderr, "ERROR: could not open game %s\n", argv[ 1 ] );
    exit( EXIT_FAILURE );
  }
  game = readGame( file );
  if( game == NULL ) {

    fprintf( stderr, "ERROR: could not read game %s\n", argv[ 1 ] );
    exit( EXIT_FAILURE );
  }
  fclose( file );

  hostent = gethostbyname( argv[ 2 ] );
  if( hostent == NULL ) {

    fprintf( stderr, "ERROR: could not look up address for %s\n", argv[ 2 ] );
    exit( EXIT_FAILURE );
  }

  if( sscanf( argv[ 3 ], "%"SCNu16, &port ) < 1 ) {

    fprintf( stderr, "ERROR: invalid port %s\n", argv[ 3 ] );
    exit( EXIT_FAILURE );
  }

  if( ( sock = socket( AF_INET, SOCK_STREAM, 0 ) ) < 0 ) {

    fprintf( stderr, "ERROR: could not open socket\n" );
    exit( EXIT_FAILURE );
  }

  addr.sin_family = AF_INET;
  addr.sin_port = htons( port );
  memcpy( &addr.sin_addr, hostent->h_addr_list[ 0 ], hostent->h_length );

  if( connect( sock, (struct sockaddr *)&addr, sizeof( addr ) ) < 0 ) {

    fprintf( stderr, "ERROR: could not open connect to %s:%"PRIu16"\n",
	     argv[ 2 ], port );
    exit( EXIT_FAILURE );
  }

  toServer = fdopen( sock, "w" );
  fromServer = fdopen( sock, "r" );
  if( toServer == NULL || fromServer == NULL ) {

    fprintf( stderr, "ERROR: could not get socket streams\n" );
    exit( EXIT_FAILURE );
  }

  if( fprintf( toServer, "VERSION:%"PRIu32".%"PRIu32".%"PRIu32"\n",
	       VERSION_MAJOR, VERSION_MINOR, VERSION_REVISION ) != 14 ) {

    fprintf( stderr, "ERROR: could not get send version to server\n" );
    exit( EXIT_FAILURE );
  }
  fflush( toServer );

  while( fgets( line, MAX_LINE_LEN, fromServer ) ) {

    /* ignore comments */
    if( line[ 0 ] == '#' || line[ 0 ] == ';' ) {
      continue;
    }

    len = readMatchState( line, game, &state );
    if( len < 0 ) {

      fprintf( stderr, "ERROR: could not read state %s", line );
      exit( EXIT_FAILURE );
    }

    if( stateFinished( &state.state ) ) {
      /* ignore the game over message */

      continue;
    }

    if( currentPlayer( game, &state.state ) != state.viewingPlayer ) {
      /* we're not acting */

      continue;
    }

    /* add a colon (guaranteed to fit because we read a new-line in fgets) */
    line[ len ] = ':';
    ++len;

    if( ( random() % 2 ) && raiseIsValid( game, &state.state, &min, &max ) ) {
      /* raise */

      action.type = raise;
      action.size = min + random() % ( max - min + 1 );
    } else {
      /* call */

      action.type = call;
      action.size = 0;
    }

    if( !isValidAction( game, &state.state, 0, &action ) ) {

      fprintf( stderr, "ERROR: chose an invalid action\n" );
      exit( EXIT_FAILURE );
    }

    r = printAction( game, &action, MAX_LINE_LEN - len - 1,
		     &line[ len ] );
    if( r < 0 ) {

      fprintf( stderr, "ERROR: line too long after printing action\n" );
      exit( EXIT_FAILURE );
    }
    len += r;
    line[ len ] = '\n';
    ++len;

    if( fwrite( line, 1, len, toServer ) != len ) {

      fprintf( stderr, "ERROR: could not get send response to server\n" );
      exit( EXIT_FAILURE );
    }
    fflush( toServer );
  }

  return EXIT_SUCCESS;
}
