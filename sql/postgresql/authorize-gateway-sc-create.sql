-- This is an Authorize.net implementation of the PaymentGateway
-- service contract

select acs_sc_impl__new(
	   'PaymentGateway',               	-- impl_contract_name
           'authorize-gateway',                 -- impl_name
	   'authorize-gateway'                  -- impl_owner_name
);


select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'Authorize', 			-- impl_operation_name
	   'authorize_gateway.authorize', 	-- impl_alias
	   'TCL'    				-- impl_pl
);

select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'ChargeCard', 			-- impl_operation_name
	   'authorize_gateway.chargecard', 	-- impl_alias
	   'TCL'    				-- impl_pl
);

select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'Return', 				-- impl_operation_name
	   'authorize_gateway.return', 		-- impl_alias
	   'TCL'    				-- impl_pl
);

select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'Void', 				-- impl_operation_name
	   'authorize_gateway.void', 		-- impl_alias
	   'TCL'    				-- impl_pl
);

select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'Info', 				-- impl_operation_name
	   'authorize_gateway.info', 		-- impl_alias
	   'TCL'    				-- impl_pl
);

-- Add the binding

select acs_sc_binding__new (
           'PaymentGateway',
           'authorize-gateway'
);

