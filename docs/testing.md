# Testing and Troubleshooting

Use these steps after the local Octant install is running and Octant is connected to Argo CD.


## Monitoring app health via Argo CD UI

In one terminal, run:

```bash
just port-forward-argocd
```

Then open:

```text
https://localhost:1443
```

>**Note**: Chrome will show a privacy warning because the local Argo CD port-forward uses a self-signed certificate. Choose **Advanced**, then **Proceed to localhost (unsafe)** to open the Argo CD UI.

## Connect a Datadog Agent

You can create a new Datadog agent or use an existing one.

### New Datadog Agent

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update
helm install datadog-agent -f connections/datadog/dd_values.yaml datadog/datadog --create-namespace -n datadog
kubectl -n datadog create secret generic datadog-secret --from-literal api-key=*****dd_api_key*****
```

### Existing Datadog Agent

If you already have a Datadog agent installed in the cluster, update the config using the Octant guide in the install and connect flow.

## Using mock data

If you don't have data from your services flowing in your cluster, we've got you covered. You can use our [Load Generation tool](https://github.com/MyDecisive/octant-demo-load/tree/main) to create a datadog collector, generate mock data, and forward it to your octant instance. [Install our Load Generation tool now](https://github.com/MyDecisive/octant-demo-load/blob/main/docs/INSTALL.md#install--run-macos-apple-silicon)!

## Live Validation Metrics

Use this Prometheus dashboard to inspect validation failures:

[Metrics for Validation Dashboard](http://localhost:9090/graph?g0.expr=mdai_fidelity_attribute_checks_total&g0.tab=1&g0.display_mode=lines&g0.show_exemplars=0&g0.range_input=1h&g1.expr=mdai_fidelity_required_attribute_checks_total&g1.tab=1&g1.display_mode=lines&g1.show_exemplars=0&g1.range_input=1h&g2.expr=mdai_fidelity_signal_checks_total&g2.tab=1&g2.display_mode=lines&g2.show_exemplars=0&g2.range_input=1h&g3.expr=mdai_fidelity_required_signal_checks_total&g3.tab=1&g3.display_mode=lines&g3.show_exemplars=0&g3.range_input=1h&g4.expr=otelcol_receiver_accepted_log_records_total%7Bservice_name%3D%22test-dd-sampling-lb-collector%22%2C%20receiver%3D%22datadog%22%7D&g4.tab=1&g4.display_mode=lines&g4.show_exemplars=0&g4.range_input=1h&g5.expr=otelcol_exporter_sent_log_records_total%7Bservice_name%3D%22test-dd-log-sampling-collector%22%2Cexporter%3D%22datadog%22%7D&g5.tab=1&g5.display_mode=lines&g5.show_exemplars=0&g5.range_input=1h&g6.expr=otelcol_exporter_sent_spans_total%7Bservice_name%3D%22test-dd-trace-sampling-collector%22%2Cexporter%3D%22datadog%22%7D&g6.tab=1&g6.display_mode=lines&g6.show_exemplars=0&g6.range_input=1h)

## Debug the Validator

Validator checks can occasionaly fail while data is still moving through the system. The validation happens quickly, but I/O metrics can take time to populate.

Review validator service logs for failed fidelity matches:

```bash
kubectl logs -n mdai svc/test-dd-telemetry-validation-fidelity-validator --since=20s \
  | grep -E '"policy_pass":false' \
  | grep -o '"correlation_id":"[^"]*"' \
  | cut -d'"' -f4 \
  | sort -u
```

Port-forward the validator service to port `8080`:

```bash
kubectl -n mdai port-forward svc/test-dd-telemetry-validation-fidelity-validator 8080:8080
```

Then open a result by replacing `<correlation_id>` with one of the values from the command output:

```text
http://localhost:8080/results/<correlation_id>
```

The result view shows the payload comparison in more detail to help you understand why some of your payloads are failing the validation check.
