using Microsoft.SqlServer.Server;

namespace CLRFunctions
{
    public class Regex
    {
        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static string Replace(string input, string pattern, string replacement)
        {
            if (input == null || pattern == null || replacement == null)
                return input;
            return System.Text.RegularExpressions.Regex.Replace(input, pattern, replacement);

        }
    }
}