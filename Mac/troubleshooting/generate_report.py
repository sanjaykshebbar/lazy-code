import json

with open("network_usage.json") as f:
    data = json.load(f)

rows = ""
for app in data:
    rows += f"""
    <tr class="border-b">
        <td class="px-4 py-2">{app['process']}</td>
        <td class="px-4 py-2">{round(app['bytes_in']/1024/1024,2)} MB</td>
        <td class="px-4 py-2">{round(app['bytes_out']/1024/1024,2)} MB</td>
    </tr>
    """

html = f"""
<!DOCTYPE html>
<html>
<head>
<title>Mac Network Usage Report</title>
<script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 p-10">

<div class="max-w-5xl mx-auto bg-white shadow-lg rounded-xl p-6">

<h1 class="text-3xl font-bold mb-6">macOS Network Usage Report</h1>

<table class="min-w-full border">

<thead class="bg-gray-200">
<tr>
<th class="px-4 py-2 text-left">Application</th>
<th class="px-4 py-2 text-left">Download</th>
<th class="px-4 py-2 text-left">Upload</th>
</tr>
</thead>

<tbody>
{rows}
</tbody>

</table>

</div>

</body>
</html>
"""

with open("network_report.html","w") as f:
    f.write(html)

print("HTML report generated: network_report.html")
