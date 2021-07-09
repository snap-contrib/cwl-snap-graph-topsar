$graph:  
- baseCommand: stac2safe
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: docker.terradue.com/stac2safe:latest
  id: stac2safe
  arguments:
    - -p 
    - sar:product_type=SLC
    - -p 
    - mission=sentinel-1
  inputs:
    input_reference:
      inputBinding:
        position: 1
        prefix: --input_reference
      type: Directory
  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /srv/conda/envs/env_stac2safe/bin:/srv/conda/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
    ResourceRequirement: {}

- baseCommand: insar-dim2stac
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: docker.terradue.com/insar-dim2stac:latest
  id: dim2stac
  inputs:
    inp1:
      inputBinding:
        position: 1
        prefix: --input-dimap
      type: Directory
    inp2:
      inputBinding:
        position: 2
        prefix: --primary
      type: Directory
    inp3:
      inputBinding:
        position: 3
        prefix: --secondary
      type: Directory
  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/srv/conda/envs/env_dim2stac/bin
        JAVA_HOME: /srv/conda/envs/env_snap/snap/jre
        HOME: /tmp
        SNAP_HOME: /tmp/.snap
    ResourceRequirement: {}


- baseCommand: gpt
  hints:
    DockerRequirement:
      dockerPull: docker.terradue.com/snap-gpt:latest
  class: CommandLineTool
  id: ifg
  arguments:
    - prefix: -PoutFile=
      separate: false
      valueFrom: |
            ${ 
                return  'IW_ifg.dim'; 
            }
    - valueFrom: "/graphs/topsar/read-split-ifg.xml"
      position: 4
  inputs:
    inp1:
      inputBinding:
        position: 1
        prefix: -PinFileP=
        separate: false
        valueFrom: ${ return inputs.inp1.path + '/manifest.safe'; }
      type: Directory
    inp2:
      inputBinding:
        position: 2
        prefix: -PinFileS=
        separate: false
        valueFrom: ${ return inputs.inp2.path + '/manifest.safe'; }
      type: Directory
    inp3:
      inputBinding:
        position: 3
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
        JAVA_HOME: /srv/conda/envs/env_snap/snap/jre
        HOME: /tmp
        SNAP_HOME: /tmp/.snap
    ResourceRequirement: {}
    InlineJavascriptRequirement: {}

  #stderr: std.err
  #stdout: std.out
- baseCommand: gpt
  hints:
    DockerRequirement:
      dockerPull: docker.terradue.com/snap-gpt:latest
  class: CommandLineTool
  id: merge
  arguments:
    - valueFrom: | #"/graphs/topsar/topsar-merge-write.xml"
                ${
                  var array = [inputs.inp1, inputs.inp2, inputs.inp3];

                  var filtered = array.filter(function (el) {
                    return el != "";
                  });

                  switch(filtered.length) {
                    case 1:
                      return "/graphs/topsar/topsar-merge-write-1-swath.xml"
                      break;
                    case 2:
                      return "/graphs/topsar/topsar-merge-write-2-swaths.xml"
                      break;
                    default:
                      return "/graphs/topsar/topsar-merge-write-all-swaths.xml"
                  }
                }
      position: 4
  inputs:
    inp1:
      inputBinding:
        position: 1
        prefix: -PinFile1=
        separate: false
        valueFrom: ${ return inputs.inp1.path + '/IW_ifg.dim'; }
      type: Directory
    inp2:
      inputBinding:
        position: 2
        prefix: -PinFile2=
        separate: false
        valueFrom: ${ if ( inputs.inp2 != "") 
                        return inputs.inp2.path + '/IW_ifg.dim'; 
                      else
                        return inputs.inp2;
                      }
      type: [string, Directory]
    inp3:
      inputBinding:
        position: 3
        prefix: -PinFile3=
        separate: false
        valueFrom: ${ if ( inputs.inp3 != "") 
                        return inputs.inp3.path + '/IW_ifg.dim';
                      else
                        return inputs.inp3;
                       }
      type: [string, Directory]
  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /srv/conda/envs/env_snap/snap/bin:/usr/share/java/maven/bin:/usr/share/java/maven/bin:/opt/anaconda/bin:/opt/anaconda/condabin:/opt/anaconda/bin:/usr/lib64/qt-3.3/bin:/usr/share/java/maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
        JAVA_HOME: /srv/conda/envs/env_snap/snap/jre
        HOME: /tmp
        SNAP_HOME: /tmp/.snap
    ResourceRequirement: {}
    InlineJavascriptRequirement: {}

  #stderr: std.err
  #stdout: std.out


- class: Workflow
  doc: SNAP SAR Calibration
  id: main
  inputs:
    #subswath:
    #  type: string[]
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
    - node_3/results
    type: Directory
      
  requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

  steps:
    node_01:
      in: 
        input_reference: primary
      out:
      - results
      run: '#stac2safe'
    node_02:
      in: 
        input_reference: secondary
      out:
      - results
      run: '#stac2safe'
    node_1:
      in:
        inp1: node_01/results
        inp2: node_02/results
        inp3: 
          default: ["IW1"]# , "IW2", "IW3"]
      out:
      - results
      run: '#ifg'
      scatter: inp3
      scatterMethod: dotproduct
    node_2:
      in: 
        inp1: 
          source: node_1/results
          valueFrom: |
            ${
              return self[0]; 
            }
        inp2: 
          source: node_1/results
          valueFrom: |
            ${
              if (self.length >= 2)
                return self[1];
              else
                return "";
            }
        inp3: 
          source: node_1/results
          valueFrom: |
            ${
              if (self.length >= 3)
                return self[2];
              else
                return "";
            }

      out:
      - results
      run: '#merge'
    node_3:
      in: 
        inp1:
          source: node_2/results
          valueFrom: ${ return self }
        inp2: primary
        inp3: secondary
      out:
      - results
      run: '#dim2stac'
cwlVersion: v1.0