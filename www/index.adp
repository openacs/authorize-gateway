<master>
  <property name="title">@title@</property>
  <property name="context_bar">@context_bar@</property>

  <h2>@title@</h2>
  <table width="100%">
    <tbody>
      <tr>
	<td align="left">@context_bar@</td>
	<td align="right">&nbsp;
          <if @admin_p@ eq 1>
            [ <a href="admin/">Administer</a> ]
          </if>
        </td>
      </tr>
    </tbody>
  </table>
  <hr>
  <p>This package has no user pages.</p>
