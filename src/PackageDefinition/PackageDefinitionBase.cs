using System;
using System.Reflection;
using System.Management.Automation;

namespace UMNAutoPackger
{
    public class PackageDefinitionBase
    {
        public void ReplaceVariable(string variableName, string value)
        {
            PropertyInfo[] propertyInfos;
            propertyInfos = this.GetType().GetProperties();

            foreach (PropertyInfo propertyInfo in propertyInfos)
            {
                Console.WriteLine("Working on: " + propertyInfo.Name);
                if (propertyInfo.PropertyType.IsArray)
                {
                    Array a = (Array)propertyInfo.GetValue(this);
                    if (null != a)
                    {
                        if (a.GetType().ToString().StartsWith("UMN"))
                        {
                            for (int i = 0; i < a.Length; i++)
                            {
                                object obj = a.GetValue(i);
                                MethodInfo method = obj.GetType().GetMethod("ReplaceVariable");
                                object[] arguments = new object[] { variableName, value };

                                if (null == method)
                                {
                                    if (obj.ToString().Contains(variableName))
                                    {
                                        propertyInfo.SetValue(this, obj.ToString().Replace(variableName, value));
                                    }
                                }
                                else
                                {
                                    try
                                    {
                                        method.Invoke(obj, arguments);
                                    }
                                    catch (Exception e)
                                    {
                                        Console.WriteLine(e.InnerException);
                                    }
                                }
                            }
                        }
                        else
                        {
                            for (int i = 0; i < a.Length; i++)
                            {
                                object obj = a.GetValue(i);
                                if (obj.ToString().Contains(variableName))
                                {
                                    propertyInfo.SetValue(this, obj.ToString().Replace(variableName, value));
                                }
                            }
                        }
                    }
                }
                else
                {
                    object o = propertyInfo.GetValue(this);
                    if (null != o && propertyInfo.PropertyType == typeof(string))
                    {
                        if (o.ToString().Contains(variableName))
                        {
                            propertyInfo.SetValue(this, o.ToString().Replace(variableName, value));
                        }
                    }
                }
            }
        }
    }
}
