<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="authorize_gateway.log_results.do-insert">      
    <querytext>
      insert into authorize_gateway_result_log 
        (transaction_id, txn_attempted_type, txn_attempted_time, response, response_code, 
         response_reason_code, response_reason_text, auth_code, avs_code, amount) 
        values 
        (:transaction_id, :txn_attempted_type, :txn_attempted_time, :response, :response_code, 
         :response_reason_code, :response_reason_text, :auth_code, :avs_code, :amount)
    </querytext>
  </fullquery>

</queryset>