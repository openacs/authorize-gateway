<master>
  <property name="title">@title@</property>
  <property name="signatory">@signatory@</property>
  <property name="header_stuff"><link href="index.css" type="text/css" rel="stylesheet"></property>
  <if @admin_p@ and @authorize_gateway_mounted@>
    <property name="context_bar"><table width="100%"><tbody><tr><td align="left">@context_bar@</td><td align="right">[ <a href="@package_url@admin/">Administer</a> ]</td></tr> </tbody></table></property>
  </if>
  <else>
    <property name="context_bar">@context_bar@</property>
  </else>

  <h2>Why</h2>

  <p>The @package_name@ implements the <if @payment_gateway_installed@
    eq 1><a href="/doc/payment-gateway"></if>Payment Service
    Contract<if @payment_gateway_installed@ eq 1></a></if> for the <a
    href="http://www.authorize.net">Authorize.net</a> on-line merchant
    services.</p>

  <h2>Background</h2>

  <p>Since the development of the <if @ecommerce_installed@ eq 1><a
      href="/doc/ecommerce"></if>ecommerce package<if
      @ecommerce_installed@ eq 1></a></if> VeriSign bought the
      CyberCash credit card acceptance service that the ecommerce
      package was build upon. VeriSign merged the CyberCash API with
      their own product PayflowPro which left the ecommerce package
      without a functioning credit card service.</p>

  <p><a href="mailto:janine@furfly.net">Janine Sisk</a> of <a
      href="http://www.furfly.net">furfly.net</a> and <a
      href="mailto:bart.teeuwisse@7-sisters.com">Bart Teeuwisse</a>
      teamed up to design a general purpose payment service contract
      and to create the first implementations of the contract. Janine
      developed the interface to PayflowPro the successor of CyberCash
      while Bart created the gateway to Authorize.net.</p>

  <p><a href="http://www.berklee.edu">Berklee College Of Music</a>
    sponsored the creation of the @package_name@ and the integration
    with the <if @ecommerce_installed@ eq 1><a
    href="/doc/ecommerce"></if>ecommerce package<if
    @ecommerce_installed@ eq 1></a></if>.</p>

  <h2>Usage</h2>

  <p class="note">Note: This release has been developed on PostgreSQL
    only. Please report any problems you might find in the <a
    href="http://openacs.org/sdm/">OpenACS SDM</a>. The SDM can also
    be used to contribute patches to the @package_name@ package (for
    example to add Oracle support).</p>

  <p>The @package_name@ requires <a
    href="http://www.scottg.net/webtools/aolserver/modules/nsopenssl/">nsopenssl</a>
    and <a href="http://dqd.com/~mayoff/aolserver/">dqd_utils</a> to
    be installed. Nsopenssl provides the ns_httpsget and ns_httpspost
    instructions to connect to the secure Authorize.net Direct Connect
    server. Dqd_utils provides the dqd_md5 instruction to validate the
    response from the Authorize.net Direct Connect server. Please
    follow the installation instructions included with these
    packages.</p>

  <p>The @package_name@ is the intermediary between OpenACS packages
    and the Authorize.net credit card acceptance services. This
    gateway accepts calls to the Payment Service Contract operations,
    forwards the information to Authorize.net and decodes the response
    before returning the outcome back to the calling package while
    keeping a log of all communication with Authorize.net. The log is
    accessible from the <if @authorize_gateway_mounted@><a
    href="@package_url@admin"></if>@package_name@ administration<if
    @authorize_gateway_mounted@></a></if>.</p>

  <p>The @package_name@ needs to be configured before it can connect
    to Authorize.net and access your account with
    Authorize.net. Configuration is via <if
    @authorize_gateway_mounted@><a
    href="/admin/site-map/parameter-set?package%5fid=@package_id@&section%5fname=all"></if>@package_name@
    parameters<if @authorize_gateway_mounted@></a></if>. The package
    has 9 parameters:</p>

  <ol>
    <li>

      <h3>CreditCardsAccepted</h3>

      <p>A list of credit cards accepted by your Authorize.net
	account. Calling applications can use this list of overwrite
	it with their own list so that applications can choose to
	accept only a subset of the cards your Authorize.net account
	can handle.</p>

    </li>
    <li>

      <h3>description</h3> 

      <p>The description of the transaction as it will appear on the
	customer's statement. E.g. 'ACME Widgets'</p>

    </li>
    <li>

      <h3>test_request</h3>

      <p>Switch the communication with Authorize.net over to Test
	mode. Useful to test the communication with Authorize.net from
	the calling package. The default value is 'False'.</p>

      <p class="note">Note: Transactions authorized in test mode do
	<strong>not</strong> return a valid transaction ID and
	<strong>will</strong> fail they are being post-authorized.</p>

    </li>
    <li>

      <h3>authorize_url</h3>

      <p>The location (URL) of the Authorize.net Gateway. Unless you
	received a different location from Authorize.net there is no
	need to change the default value. </p>

    </li>
    <li>

      <h3>referer_url</h3>

      <p>The location (URL) of your web site where the communication
	with Authorize.net originates from. This URL be listed as a
	valid ADC URL in the list of accepted referers in the ADC
	settings. Do <strong>not</strong> leave this secret blank, it
	ensures the requests received by Authorize.net are comming
	from the @package_name@ and not some spoof.</p>

    </li>
    <li>
      
      <h3>authorize_login</h3>

      <p>Your login name to Authorize.net. This is the same login ID
	that you use to login to the Authorize.net <a
	  href="https://merchant.authorize.net">virtual terminal</a>.</p>

    </li>
    <li>
      
      <h3>authorize_password</h3>

      <p>The password to your Authorize.net account. This is the same login ID
	that you use to login to the Authorize.net virtual terminal.</p>

      <p class="note">Advice: Keep your login name and the login password
	secret as they give access all credit card transactions
	including all credit card numbers of the cards used in the
	transactions. Make sure to secure the access to the OpenACS
	admin pages with SSL.</p>

    </li>
    <li>

      <h3>md5_secret</h3>

      <p>The MD5 Hash Secret from the <a
	  href="https://merchant.authorize.net">Automated Direct Connect</a>
	(ADC) settings in Authorize.net. This secret should have the
	same value your secret in the ADC settings. Do
	<strong>not</strong> leave this secret blank, it ensures that
	the @package_name@ is really talking to Authorize.net and not
	some spoof.</p>

    </li>
    <li>

      <h3>field_encapsulator</h3>

      <p>The field encapsulation character in the Automated Direct
	Connect (ADC) settings of Authorize.net. You can opt to use a
	field encapsulation character to wrap around the elements in the
	response from Authorize.net. It reduces the risk that unusual
	characters in the data send to Authorize.net and echoed back
	trip the decoding of the response. With only a field separator
	it is possible that the decoding is disrupted by a name or
	address field containing the same character as the field
	separator. If you choose to use a field encapsulator make sure
	that the value is same as the value in the ADC settings.</p>

    </li>
    <li>

      <h3>field_seperator</h3>

      <p>The field seperator in Automated Direct Connect (ADC)
	Settings of Authorize.net. This is the character that delimits
	the elements in the response from Authorize.net. It is advisable
	to also use a field encapsulator. Make sure that the value is
	same as the value in the ADC settings.</p>

    </li>
  </ol>

  <h2>API Reference</h2>

  <p>The <if @payment_gateway_installed@ eq 1><a
      href="/doc/payment-gateway"></if>Payment Service Contract<if
    @payment_gateway_installed@ eq 1></a></if> explains the API to other
  packages in detail.</p>
  
  <p>Visit the <a
      href="https://secure.authorize.net/docs/index.pml">Authorize.net
      developer documentation</a> for in-depth coverage of the
    Authorize.net API that this package interfaces to. Be sure to check
    out the additional security measures you can take.</p>

  <h2>Credits</h2>

  <p>The @package_name@ was designed and written by <a
      href="mailto:bart.teeuwisse@7-sisters.com">Bart Teeuwisse</a>
      for <a href="http://www.berklee.edu">Berklee College Of
      Music</a> while working as a subcontractor for <a
      href="http://www.furfly.net">furfly.net</a>.</p>

  <p>The @package_name@ is free software; you can redistribute it
    and/or modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.</p>

  <p>The @package_name@ is distributed in the hope that it will be
    useful, but WITHOUT ANY WARRANTY; without even the implied
    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU General Public License for more details.</p>

  <p>A <a href="license">copy of the GNU General Public License</a> is
    included. If not write to the Free Software Foundation, Inc., 59
    Temple Place, Suite 330, Boston, MA 02111-1307 USA
