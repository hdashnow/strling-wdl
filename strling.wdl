workflow SimpleVariantDiscovery {

  meta {
      author: "Harriet Dashnow"
      email: "h.dashnow@gmail.com"
      description: "Run STRling (github.com/quinlan-lab/STRling) in individual calling mode to detect and genotype STRs"
  }

  # Columns from the sample_set
  Array[String] crams

  File ref_fasta
  File ref_str

  scatter (cram in crams) {

    call str_extract {
      input:
        ref_fasta = ref_fasta,
        ref_str = ref_str,
        cram = cram,
    }

     call str_call_individual {
      input:
        ref_fasta = ref_fasta,
        ref_str = ref_str,
        bin = str_extract.bin,
        cram = cram,
    }

  }

}

task str_extract {
  File ref_fasta
  File ref_str
  File cram
  String sample = basename(cram, ".cram")

  command {
    strling extract \
      -f ${ref_fasta} \
      -g ${ref_str} \
      ${cram} \
      ${sample}.bin
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "hdashnow/strling:latest"
  }
  output {
    File bin = "${sample}.bin"
  }
}

task str_call_individual {
  File ref_fasta
  File ref_str
  File cram
  String sample = basename(cram, ".cram")
  File bin

  command {
    strling call \
      -f ${ref_fasta} \
      -o ${sample} \
      ${cram} \
      ${bin}
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "hdashnow/strling:latest"
  }
  output {
    File output_bounds = "${sample}-bounds.txt"
    File output_unplaced = "${sample}-unplaced.txt"
    File output_genotype = "${sample}-genotype.txt"
  }
}

