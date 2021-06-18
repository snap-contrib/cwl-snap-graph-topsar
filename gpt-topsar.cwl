$graph:    
- baseCommand: gpt
  hints:
    DockerRequirement:
      dockerPull: snap:latest
  class: CommandLineTool
  id: ifg
  arguments:
    - prefix: -PoutFile=
      separate: false
      valueFrom: |
            ${ 
                // return inputs.inp4 +  '_ifg.dim'; 
                return  'IW_ifg.dim'; 
            }
  inputs:
    inp1:
      inputBinding:
        position: 1
      type: File
    inp2:
      inputBinding:
        position: 2
        prefix: -PinFileP=
        separate: false
        valueFrom: ${ return inputs.inp2.path + '/manifest.safe'; }
      type: Directory
    inp3:
      inputBinding:
        position: 3
        prefix: -PinFileS=
        separate: false
        valueFrom: ${ return inputs.inp3.path + '/manifest.safe'; }
      type: Directory
    inp4:
      inputBinding:
        position: 4
        prefix: -PsubSwath=
        separate: false
      type: string
  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /srv/conda/envs/env_snap/snap/bin:/usr/share/java/maven/bin:/usr/share/java/maven/bin:/opt/anaconda/bin:/opt/anaconda/condabin:/opt/anaconda/bin:/usr/lib64/qt-3.3/bin:/usr/share/java/maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
        PREFIX: /opt/anaconda/envs/env_snap
    ResourceRequirement: {}
    InlineJavascriptRequirement: {}

  #stderr: std.err
  #stdout: std.out
- baseCommand: gpt
  hints:
    DockerRequirement:
      dockerPull: snap:latest
  class: CommandLineTool
  id: merge
  inputs:
    inp1:
      inputBinding:
        position: 1
      type: File
    inp2:
      inputBinding:
        position: 2
        prefix: -PinFile1=
        separate: false
        valueFrom: ${ return inputs.inp2.path + '/IW_ifg.dim'; }
      type: Directory
    inp3:
      inputBinding:
        position: 2
        prefix: -PinFile2=
        separate: false
        valueFrom: ${ return inputs.inp3.path + '/IW_ifg.dim'; }
      type: Directory
    inp4:
      inputBinding:
        position: 2
        prefix: -PinFile3=
        separate: false
        valueFrom: ${ return inputs.inp4.path + '/IW_ifg.dim'; }
      type: Directory
  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /srv/conda/envs/env_snap/snap/bin:/usr/share/java/maven/bin:/usr/share/java/maven/bin:/opt/anaconda/bin:/opt/anaconda/condabin:/opt/anaconda/bin:/usr/lib64/qt-3.3/bin:/usr/share/java/maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
        PREFIX: /opt/anaconda/envs/env_snap
    ResourceRequirement: {}
    InlineJavascriptRequirement: {}

  #stderr: std.err
  #stdout: std.out


- class: Workflow
  doc: SNAP SAR Calibration
  id: main
  inputs:
    snap_graph_ifg:
      doc: SNAP Graph
      label: SNAP Graph
      type: File
    snap_graph_merge:
      doc: SNAP Graph
      label: SNAP Graph
      type: File
    subswath:
      type: string[]
    primary:
      doc: Sentinel-1 SLC primary product SAFE Directory
      label: Sentinel-1 SLC primary product SAFE Directory
      type: Directory
    secondary: 
      doc: Sentinel-1 SLC secondary product SAFE Directory
      label: Sentinel-1 SLC secondary product SAFE Directory
      type: Directory
  label: SNAP SAR Calibration
  outputs:
  - id: wf_outputs
    outputSource:
    - node_2/results
    type: Directory
      
  requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  steps:
    node_1:
      in:
        inp1: snap_graph_ifg
        inp2: primary
        inp3: secondary
        inp4: subswath
      out:
      - results
      run: '#ifg'
      scatter: inp4
      scatterMethod: dotproduct
    node_2:
      in: 
        inp1: snap_graph_merge
        inp2: 
          source: node_1/results
          valueFrom: |
            ${
              return self[0]; 
            }
        inp3: 
          source: node_1/results
          valueFrom: |
            ${
              return self[1];
            }
        inp4: 
          source: node_1/results
          valueFrom: |
            ${
              return self[2];
            }

      out:
      - results
      run: '#merge'
cwlVersion: v1.0