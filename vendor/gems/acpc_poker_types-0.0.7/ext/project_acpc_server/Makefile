CC = gcc
CFLAGS = -O3 -Wall

all:	dealer example_player

dealer: game.c game.h evalHandTables rng.c rng.h dealer.c
	$(CC) $(CFLAGS) -o $@ game.c rng.c dealer.c

example_player: game.c game.h evalHandTables rng.c rng.h example_player.c
	$(CC) $(CFLAGS) -o $@ game.c rng.c example_player.c

clean:
	rm -f dealer example_player
