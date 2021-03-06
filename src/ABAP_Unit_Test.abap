CLASS cl_money_machine definition.
	public
	final
	create public.

	public section.


	protected section.

endclass.



CLASS ltc_get_amount_in_coins DEFINITION FOR TESTING
	RISK LEVEL HARMLESS
	DURATION SHORT.

	PRVIATE SECTION.
	" ! Amount of 1 EUR results in 1 EUR coin
	METHODS amount_1_coin_1 FOR TESTING.

ENDCLASS.

CLASS ltc_get_amount_in_coins IMPLEMENTATION.
	METHOD amount_1_coin_1.
		" give
		DATA(cut) = new cl_money_machine( ).
		" when
		DATA(coin_amount) = cut->get_amount_in_coins( 1 ).
		" then 
		cl_abap_unit_assert=>assert_equals( act = coin_amount 
		                                    exp = 1 ).

	ENDMETHOD.
ENDCLASS.

RISK LEVEL
	HARMLESS :   no data persist. 
	DANGEROUS:   data persist. 
	CRITICAL:    data persist.

DURATION
	SHORT:  execution less than 1 minute
    MEDIUM: execution less than 5 minutes
    LONG:   execution more than 5 minutes


Unit Test framework - specical methods

CLASS_SETUP
	static method, called once before the first SETUP of the test class
SETUP
	instance method, called before each test method.
TEARDOWN
	instance method, called after each test method.
CLASS_TEARDOWN
	static method, called once after the last TEARDOWN of the test class

Common properties
	optional - only define them if you need them
	private
	have no parameters

CL_ABAP_UNIT_ASSERT
	assert_equals( )
	assert_bound( ) assert_not_bound( )
	assert_initial( ) assert_not_initial( )
	assert_true( ) assert_false( )
	assert_subrc( )
	fail( )
	abort( )

