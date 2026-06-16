from diagrams import Diagram, Cluster, Edge
from diagrams.azure.compute import VM, ContainerApps
from diagrams.azure.network import VirtualNetworks
from diagrams.azure.analytics import LogAnalyticsWorkspaces
from diagrams.azure.general import Subscriptions
from diagrams.saas.chat import Slack
from diagrams.onprem.iac import Terraform
from diagrams.generic.blank import Blank

graph_attrs = {"fontsize": "13", "bgcolor": "white", "pad": "0.5", "splines": "ortho"}
node_attrs = {"fontsize": "11"}

with Diagram(
    "Azure Incident Responder",
    filename="docs/architecture",
    outformat="png",
    show=False,
    direction="LR",
    graph_attr=graph_attrs,
    node_attr=node_attrs,
):
    tf = Terraform("Terraform\n(IaC)")

    with Cluster("Incident detection"):
        vm = VM("Target VM\n(Standard_B1s)")
        alert = LogAnalyticsWorkspaces("Metric alert\nPercentage CPU >= 80%")
        ag = Subscriptions("Action group\n(common alert schema)")
        vm >> Edge(label="Percentage CPU") >> alert >> ag

    with Cluster("n8n control plane"):
        with Cluster("Container Apps Environment"):
            n8n = ContainerApps("n8n\nrunbook engine\n(*.azurecontainerapps.io TLS)")

    slack = Slack("Slack\n#incidents")
    haiku = Blank("Claude Haiku\nincident summary")

    ag >> Edge(label="HTTPS webhook") >> n8n

    n8n >> Edge(label="summarize") >> haiku
    n8n >> Edge(label="incident / resolve / escalate") >> slack
    n8n >> Edge(label="restart VM (OAuth2)\n+ verify metric", style="bold") >> vm

    tf >> Edge(style="dotted") >> n8n
    tf >> Edge(style="dotted") >> alert
