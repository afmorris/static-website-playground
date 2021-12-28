using System.IO;
using Pulumi;
using Pulumi.Aws.S3;
using Pulumi.Aws.S3.Inputs;
using Pulumi.Cloudflare;

class MyStack : Stack
{
    public MyStack()
    {
        siteDomain = "aws-pulumi-static.morriscloud.com";
        SetupAws();
        SetupCloudflare();
    }

    private void SetupAws()
    {
        var bucket = new Bucket(siteDomain, new BucketArgs
        {
            BucketName = siteDomain,
            Acl = "public-read",
            Policy = File.ReadAllText("policy.json"),
            Website = new BucketWebsiteArgs
            {
                IndexDocument = "index.html",
                ErrorDocument = "index.html"
            },
            Tags = {
                { "Project", "Static Website Playground" }
            }
        });

        var bucketObject = new BucketObject("index.html", new BucketObjectArgs
        {
            Bucket = bucket.BucketName,
            Source = new FileAsset("index.html"),
            ContentType = "text/html"
        });

        this.BucketName = bucket.Id;
        this.BucketEndpoint = bucket.WebsiteEndpoint;
    }

    private void SetupCloudflare()
    {
        var zone = Output.Create(GetZone.InvokeAsync(new GetZoneArgs
        {
            Name = "morriscloud.com"
        }));

        var record = new Record(siteDomain, new RecordArgs
        {
            ZoneId = zone.Apply(z => z.Id),
            Name = siteDomain,
            Value = this.BucketEndpoint,
            Type = "CNAME",
            Ttl = 1,
            Proxied = true
        });
    }

    private string siteDomain { get; set; }

    [Output]
    public Output<string> BucketName { get; set; }

    [Output]
    public Output<string> BucketEndpoint { get; set; }
}
