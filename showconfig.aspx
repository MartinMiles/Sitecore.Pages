@using Sitecore.Configuration
@{
    var xmlDocument = Factory.GetConfiguration();

    if (Request.QueryString.HasKeys() && Request.QueryString.AllKeys.Any(x => x.Equals("save")))
    {
        var appDataPath = Context.Request.MapPath("~/App_Data");
        if (!string.IsNullOrWhiteSpace(appDataPath))
        {
            var xmlPath = Path.Combine(appDataPath, $"{Context.Server.MachineName}-Config.xml");
            xmlDocument.Save(xmlPath);
        }
    }

    Response.ContentType = "text/xml";
    Response.Write(xmlDocument.OuterXml);
}