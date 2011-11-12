// Ruby includes
#include <ruby.h>
#include <ruby/io.h>

// ACPC includes
#include "../../external/project_acpc_server/game.h"
#include "../../external/project_acpc_server/evalHandTables"

static VALUE cHandEvaluator;

/*
 * @param [VALUE] self The class from which this method was called.  This is
 *    an implicit argument.
 * @param [VALUE] ruby_card_list The list of numeric ACPC represented cards in
 *    a Ruby array.
 * @return [int] The rank of the hand.
 */
static VALUE rank_hand(VALUE self, VALUE ruby_card_list) {
   VALUE* card_list = RARRAY_PTR(ruby_card_list);
   int card_list_length = RARRAY_LEN(ruby_card_list);
  
   int card;
   Cardset card_set = emptyCardset();
   
   int i;
   for(i = 0; i < card_list_length; ++i) {
      card = NUM2INT(card_list[i]);
      addCardToCardset(&card_set, suitOfCard(card),
         rankOfCard(card));
   }
 
   return INT2NUM(rankCardset(card_set));
}

void Init_hand_evaluator() {
   cHandEvaluator = rb_define_module("HandEvaluator");
   rb_define_module_function(cHandEvaluator, "rank_hand", rank_hand, 1);
}
