<?php
/*
1. install theme
2. activate theme
3. visit /wp-admin/admin.php?page=td_cake_panel
4. copy server ID from "YOUR SERVER ID" and paste it to $s_id in this file
5. visit /activationkey.php
6. copy the activation key
7. copy the business ID
8. paste activation key into "TAGDIV ACTIVATION KEY" in this page: /wp-admin/admin.php?page=td_cake_panel
9. paste business ID into "ENVATO PURCHASE CODE" in this page: /wp-admin/admin.php?page=td_cake_panel
*/
$s_id = "114a5ade84c4169fe58841a2bb0863dc"; // add here your server id 
$e_id = "b09e7b94-e0e9-4cb8-9f54-2324dca538b7"; // envato orignal purchase code, can be like this format
$t_id = md5($s_id . $e_id);
echo $t_id;
?>
