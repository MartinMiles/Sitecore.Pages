<%@ page language="C#" autoeventwireup="true" %>
<%@ Import Namespace="System.Linq" %>
<script runat="server">  
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Sitecore.Context.User.IsAuthenticated)
            {
                divAuthorized.Visible = true;
                divUnauthorized.Visible = false;
                lblUser.Text = Sitecore.Context.User.DisplayName;
                lblGroups.Text = string.Join("<br/>", ((System.Security.Claims.ClaimsIdentity)Sitecore.Context.User.Identity).Claims
                    .Where(w => w.Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role" || w.Type == "groups")
                    .Select(s => s.Value));

                if (Sitecore.Context.User.IsAdministrator)
                {
                    lblAdmin.Text = "User <b>is</b> Admin";
                }
                else
                {
                    lblAdmin.Text = "User is <b>NOT</b> an Admin";
                }
            }
            else
            {
                divAuthorized.Visible = false;
                divUnauthorized.Visible = true;
            }
        }
</script>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Active Direcory Groups</title>
</head>
<body>
    <form id="form1" runat="server">
        <div runat="server" id="divAuthorized">
            <div style="font-size: large; font-weight: bold">Current user:</div>
            <div><asp:Label id="lblUser" runat="server" Text=""></asp:Label></div>
            <br />

            <div style="font-size: large; font-weight: bold">Active groups:</div>
            <div><asp:Label id="lblGroups" runat="server" Text=""></asp:Label></div>
            <br />

            <div style="font-size: large;"><asp:Label id="lblAdmin" runat="server" Text=""></asp:Label></div>
        </div>
        <div runat="server" id="divUnauthorized">
            <h1>Please log in with a valid account to see this page</h1>
        </div>
    </form>
</body>
</html>
