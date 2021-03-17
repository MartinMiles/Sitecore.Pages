<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Data.Fields" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Layouts" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Web" %>

<script runat="server">  

        private const string DatabaseName = "master";
        private const string DefaultDeviceId = "{FE5D7FDF-89C0-4D99-9AA3-B5FBD009C9F3}";
        private const string ItemsWithPresentationDetailsQuery = "/sitecore/content//*[@__Renderings != '' or @__Final Renderings != '']";
        private const string PlaceholderRegex = "_([0-9a-f]{8}[-][0-9a-f]{4}[-][0-9a-f]{4}[-][0-9a-f]{4}[-][0-9a-f]{12})";

        protected void Page_Load(object sender, EventArgs e)
        {
            var result = Iterate();

            OutputResult(result);
        }

        private void OutputResult(Dictionary<Item, List<KeyValuePair<string, string>>> result)
        {
            Response.ContentType = "text/html";

            Response.Write("<h1>" + result.Count + " items processed</h1>");
            foreach (var pair in result)
            {
                Response.Write("<h3>" + pair.Key.Paths.FullPath + "</h3>");

                foreach (var kvp in pair.Value)
                {
                    if (kvp.Key != kvp.Value)
                    {
                        Response.Write("<div>" + kvp.Key + " ==> " + kvp.Value + "</div>");
                    }
                }
            }
        }

        public Dictionary<Item, List<KeyValuePair<string, string>>> Iterate()
        {
            var result = new Dictionary<Item, List<KeyValuePair<string, string>>>();

            var master = Factory.GetDatabase(DatabaseName);
            var items = master.SelectItems(ItemsWithPresentationDetailsQuery);

            var layoutFields = new[] { FieldIDs.LayoutField, FieldIDs.FinalLayoutField };

            foreach (var itemInDefaultLanguage in items)
            {
                foreach (var itemLanguage in itemInDefaultLanguage.Languages)
                {
                    var item = itemInDefaultLanguage.Database.GetItem(itemInDefaultLanguage.ID, itemLanguage);
                    if (item.Versions.Count > 0)
                    {
                        foreach (var layoutField in layoutFields)
                        {
                            var changeResult = ChangeLayoutFieldForItem(item, item.Fields[layoutField]);

                            if (changeResult.Any())
                            {
                                if (!result.ContainsKey(item))
                                {
                                    result.Add(item, changeResult);
                                }
                                else
                                {
                                    result[item].AddRange(changeResult);
                                }
                            }
                        }
                    }
                }
            }

            return result;
        }

        private List<KeyValuePair<string, string>> ChangeLayoutFieldForItem(Item currentItem, Field field)
        {
            var result = new List<KeyValuePair<string, string>>();

            string xml = LayoutField.GetFieldValue(field);

            if (!string.IsNullOrWhiteSpace(xml))
            {
                var details = LayoutDefinition.Parse(xml);

                var device = details.GetDevice(DefaultDeviceId);
                var deviceItem = currentItem.Database.Resources.Devices["Default"];

                var renderings = currentItem.Visualization.GetRenderings(deviceItem, false);

                if (device != null && device.Renderings != null)
                {
                    bool requiresUpdate = false;

                    foreach (RenderingDefinition rendering in device.Renderings)
                    {
                        if (!string.IsNullOrWhiteSpace(rendering.Placeholder))
                        {
                            var newPlaceholder = rendering.Placeholder;
                            foreach (Match match in Regex.Matches(newPlaceholder, PlaceholderRegex, RegexOptions.IgnoreCase))
                            {
                                var renderingId = match.Value;
                                var newRenderingId = "-{" + renderingId.ToUpper().Substring(1) + "}-0";

                                newPlaceholder = newPlaceholder.Replace(match.Value, newRenderingId);

                                requiresUpdate = true;
                            }

                            result.Add(new KeyValuePair<string, string>(rendering.Placeholder, newPlaceholder));
                            rendering.Placeholder = newPlaceholder;
                        }
                    }

                    if (requiresUpdate)
                    {
                        string newXml = details.ToXml();

                        using (new EditContext(currentItem))
                        {
                            LayoutField.SetFieldValue(field, newXml);
                        }
                    }

                }
            }

            return result;
        }


</script>